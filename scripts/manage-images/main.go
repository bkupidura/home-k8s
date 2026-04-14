package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/getsops/sops/v3/decrypt"
	"github.com/google/go-containerregistry/pkg/crane"
	"github.com/google/go-jsonnet"
)

type CacheEntry struct {
	Source      string `json:"source"`
	Destination string `json:"destination"`
}

type Version struct {
	Cache []CacheEntry `json:"cache"`
}

type Versions struct {
	Versions map[string]Version `json:"versions"`
}

func main() {
	versionsFile := flag.String("file", "../../tanka/environments/prod/version.jsonnet", "Path to versions jsonnet file")
	vaultFile := flag.String("vault", "../../tanka/environments/prod/vault.enc", "Path to SOPS-encrypted vault file")
	action := flag.String("action", "", "Action to perform: cleanup|sync")
	flag.Parse()

	versionsAbs, err := filepath.Abs(*versionsFile)
	if err != nil {
		log.Printf("error: invalid versions file path: %v", err)
		os.Exit(2)
	}

	if _, err := os.Stat(versionsAbs); os.IsNotExist(err) {
		log.Printf("error: versions file not found: %s", versionsAbs)
		os.Exit(2)
	}

	vaultAbs, err := filepath.Abs(*vaultFile)
	if err != nil {
		log.Printf("error: invalid vault file path: %v", err)
		os.Exit(2)
	}

	if _, err := os.Stat(vaultAbs); os.IsNotExist(err) {
		log.Printf("error: vault file not found: %s", vaultAbs)
		os.Exit(2)
	}

	versions, err := loadVersions(versionsAbs, vaultAbs)
	if err != nil {
		log.Printf("error: %v", err)
		os.Exit(3)
	}

	switch *action {
	case "cleanup":
		if err := image_cleanup(versions); err != nil {
			log.Printf("image_cleanup failed: %v", err)
			os.Exit(5)
		}
		return
	case "sync":
		if err := image_sync(versions); err != nil {
			log.Printf("image_sync failed: %v", err)
			os.Exit(5)
		}
		return
	default:
		log.Printf("unknown action: %s", *action)
		os.Exit(6)
	}
}

// loadVersions reads vault and evaluate versions
func loadVersions(versionsPath, vaultPath string) (*Versions, error) {
	vaultData, err := readVault(vaultPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read vault: %w", err)
	}

	versions, err := readVersions(versionsPath, vaultData)
	if err != nil {
		return nil, fmt.Errorf("failed to read versions: %w", err)
	}

	return versions, nil
}

// readVault decrypts SOPS encrypted vault file and returns its content as Jsonnet code
func readVault(vaultPath string) (string, error) {
	data, err := decrypt.File(vaultPath, "")
	if err != nil {
		return "", fmt.Errorf("sops decrypt failed: %w", err)
	}

	return string(data), nil
}

// readVersions evaluates the versions jsonnet file with secrets
func readVersions(versionsPath, vaultData string) (*Versions, error) {
	vm := jsonnet.MakeVM()

	vm.ExtCode("secrets", vaultData)
	snippetCode := fmt.Sprintf(`
local v = (import "%s");
{ versions: v._version }
`, versionsPath)

	jsonOutput, err := vm.EvaluateSnippet(versionsPath, snippetCode)
	if err != nil {
		return nil, fmt.Errorf("evaluating jsonnet failed: %w", err)
	}

	var result Versions
	err = json.Unmarshal([]byte(jsonOutput), &result)
	if err != nil {
		return nil, fmt.Errorf("parsing jsonnet output failed: %w", err)
	}

	return &result, nil
}

// image_cleanup removes old image tags
func image_cleanup(v *Versions) error {
	keep := make(map[string]map[string]struct{})

	for _, version := range v.Versions {
		for _, cache := range version.Cache {
			img := cache.Destination
			if img == "" {
				continue
			}

			i := strings.LastIndex(img, ":")
			if i == -1 {
				log.Printf("skipping image without tag: %s", img)
				continue
			}
			repo := img[:i]
			tag := img[i+1:]

			if _, ok := keep[repo]; !ok {
				keep[repo] = make(map[string]struct{})
			}
			keep[repo][tag] = struct{}{}
		}
	}

	for repo, tagsToKeep := range keep {
		log.Printf("cleaning repo=%s keep=%v", repo, tagsToKeep)
		tags, err := crane.ListTags(repo)
		if err != nil {
			log.Printf("error listing tags for %s: %v", repo, err)
			continue
		}

		for _, t := range tags {
			if _, ok := tagsToKeep[t]; ok {
				continue
			}
			ref := fmt.Sprintf("%s:%s", repo, t)
			log.Printf("deleting tag %s", ref)
			if err := crane.Delete(ref); err != nil {
				log.Printf("failed to delete %s: %v", ref, err)
				continue
			}
		}
	}

	return nil
}

// image_sync synchronize images from src to dst
func image_sync(v *Versions) error {
	for service, version := range v.Versions {
		for _, cache := range version.Cache {
			log.Printf("syncing image for service %s: %s -> %s", service, cache.Source, cache.Destination)

			srcTagSlice := strings.Split(cache.Source, ":")
			dstTagSlice := strings.Split(cache.Destination, ":")

			if srcTagSlice[len(srcTagSlice)-1] != dstTagSlice[len(dstTagSlice)-1] {
				log.Printf("error: source tag doesn't match destination tag")
				continue
			}

			exists, err := image_exists(cache.Destination)
			if err != nil {
				log.Printf("error checking destination %s for service %s: %v", cache.Destination, service, err)
				continue
			}
			if exists {
				continue
			}

			img, err := crane.Pull(cache.Source)
			if err != nil {
				log.Printf("error: pulling image %s for service %s failed: %v", cache.Source, service, err)
				continue
			}

			tmpFile, err := os.CreateTemp("", "image-*.tar")
			if err != nil {
				log.Printf("error creating temp file for %s: %v", cache.Source, err)
				continue
			}
			tmpPath := tmpFile.Name()
			tmpFile.Close()

			if err := crane.Save(img, cache.Source, tmpPath); err != nil {
				log.Printf("error saving image %s to %s: %v", cache.Source, tmpPath, err)
				os.Remove(tmpPath)
				continue
			}

			imgFromDisk, err := crane.Load(tmpPath)
			if err != nil {
				log.Printf("error loading image from %s: %v", tmpPath, err)
				os.Remove(tmpPath)
				continue
			}

			if err := crane.Push(imgFromDisk, cache.Destination); err != nil {
				log.Printf("error: pushing image to %s for service %s failed: %v", cache.Destination, service, err)
				os.Remove(tmpPath)
				continue
			}

			if err := os.Remove(tmpPath); err != nil {
				log.Printf("warning: removing temp file %s failed: %v", tmpPath, err)
			}
		}
	}

	return nil
}

// image_exists checks whether the given image exists
func image_exists(image string) (bool, error) {
	_, err := crane.Manifest(image)
	if err == nil {
		return true, nil
	}

	lower := strings.ToLower(err.Error())
	if strings.Contains(lower, "manifest unknown") || strings.Contains(lower, "not found") || strings.Contains(lower, "manifestunknown") || strings.Contains(lower, "404") {
		return false, nil
	}

	return false, fmt.Errorf("checking image existence failed: %w", err)
}
