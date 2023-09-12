package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/hashicorp/vault/api"
	"github.com/joho/godotenv"
	"github.com/obolnetwork/charon/app/errors"
	"github.com/obolnetwork/charon/eth2util/keystore"
	"github.com/obolnetwork/charon/tbls"
	"github.com/obolnetwork/charon/tbls/tblsconv"
	keystorev4 "github.com/wealdtech/go-eth2-wallet-encryptor-keystorev4"
	"gopkg.in/yaml.v2"
)

func main() {
	args := os.Args[1:]
	folderPath := args[0]
	secretPath := args[1]

	// List all files in the folder
	keystoreFiles, err := getKeystoreFilesInFolder(folderPath)
	if err != nil {
		log.Fatal(err, "list keystore files")
	}

	err = godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	token := os.Getenv("VAULT_TOKEN")

	for _, keystoreFile := range keystoreFiles {
		err := processKeystoreFile(keystoreFile, secretPath, token)
		if err != nil {
			log.Fatal(err, "process keystore file")
		}
	}
}

func processKeystoreFile(filename string, secretPath string, token string) error {
	b, err := os.ReadFile(filename)
	if err != nil {
		return errors.Wrap(err, "read keystore file")
	}

	var store keystore.Keystore
	err = json.Unmarshal(b, &store)
	if err != nil {
		return errors.Wrap(err, "unmarshal keystore file")
	}

	password, err := loadPassword(filename)
	if err != nil {
		return errors.Wrap(err, "load password")
	}

	secret, err := decrypt(store, password)
	if err != nil {
		return errors.Wrap(err, "decrypt keystore")
	}

	fmt.Printf("Hex encoded private key: %s\n", fmt.Sprintf("%x", secret[:]))

	// Upload the private key to HashiCorp Vault
	err = uploadPrivateKeyToVault(secret, token, secretPath, filename)
	if err != nil {
		return errors.Wrap(err, "upload private key to Vault")
	}

	// Generate and save the YAML data to a file
	err = generateAndSaveYAML(filename, secretPath, token)
	if err != nil {
		return errors.Wrap(err, "generate and save YAML")
	}

	return nil
}

func loadPassword(keyFile string) (string, error) {
	if _, err := os.Stat(keyFile); errors.Is(err, os.ErrNotExist) {
		return "", errors.New("keystore password file not found " + keyFile)
	}

	passwordFile := strings.Replace(keyFile, ".json", ".txt", 1)
	b, err := os.ReadFile(passwordFile)
	if err != nil {
		return "", errors.Wrap(err, "read password file")
	}

	return string(b), nil
}

func decrypt(store keystore.Keystore, password string) (tbls.PrivateKey, error) {
	decryptor := keystorev4.New()
	secretBytes, err := decryptor.Decrypt(store.Crypto, password)
	if err != nil {
		return tbls.PrivateKey{}, errors.Wrap(err, "decrypt keystore")
	}

	return tblsconv.PrivkeyFromBytes(secretBytes)
}

func uploadPrivateKeyToVault(privateKey tbls.PrivateKey, token string, secretPath string, keystoreFile string) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()

	// Create a Vault client
	client, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		return errors.Wrap(err, "create Vault client")
	}

	// Authenticate to Vault
	client.SetToken(token)

	// Prepare the private key
	privateKeyHex := fmt.Sprintf("%x", privateKey[:])

	// Construct the secret name based on the keystore file name
	secretName := getSecretNameFromKeystoreFile(keystoreFile)

	// Write the private key to Vault
	data := map[string]interface{}{
		"value": privateKeyHex,
	}
	client.Sys().Mount(secretPath, &api.MountInput{
		Type: "kv",
		Options: map[string]string{
			"version": "2",
		},
	})
	// defer client.Sys().Unmount(secretPath)
	// Create a kvV2 secret engine
	var kv = client.KVv2(secretPath)
	_, err = kv.Put(ctx, secretName, data)
	if err != nil {
		return errors.Wrap(err, "create Vault client")
	}

	fmt.Println("Private key uploaded to Vault successfully")
	return nil
}

func generateAndSaveYAML(keystoreFile string, secretPath string, token string) error {
	keyPath := fmt.Sprintf("/v1/%s/data/%s", secretPath, getSecretNameFromKeystoreFile(keystoreFile))
	// Create a struct to represent the YAML data
	yamlData := struct {
		Type       string `yaml:"type"`
		KeyType    string `yaml:"keyType"`
		TLSEnabled string `yaml:"tlsEnabled"`
		KeyPath    string `yaml:"keyPath"`
		KeyName    string `yaml:"keyName"`
		ServerHost string `yaml:"serverHost"`
		ServerPort string `yaml:"serverPort"`
		Timeout    string `yaml:"timeout"`
		Token      string `yaml:"token"`
	}{
		Type:       "hashicorp",
		KeyType:    "BLS",
		TLSEnabled: "false",
		KeyPath:    keyPath,
		KeyName:    "value",
		ServerHost: "vault.vault.svc.cluster.local",
		ServerPort: "8200",
		Timeout:    "10000",
		Token:      token,
	}

	// Marshal the struct into YAML format
	yamlBytes, err := yaml.Marshal(&yamlData)
	if err != nil {
		return errors.Wrap(err, "marshal YAML data")
	}

	// Define the YAML file name based on the keystore file
	yamlFileName := secretPath + ".yaml"

	// Open the file for writing (create if not exists, append otherwise)
	file, err := os.OpenFile(yamlFileName, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0644)
	if err != nil {
		return errors.Wrap(err, "open file")
	}
	defer file.Close()

	// Add "---" as a separator if the file already exists or is being created
	_, err = file.WriteString("---\n")
	if err != nil {
		return errors.Wrap(err, "write separator")
	}

	// Write the YAML data to the file
	_, err = file.Write(yamlBytes)
	if err != nil {
		return errors.Wrap(err, "write YAML to file")
	}

	fmt.Printf("YAML data saved to %s\n", yamlFileName)
	return nil
}

func getKeystoreFilesInFolder(folderPath string) ([]string, error) {
	files, err := ioutil.ReadDir(folderPath)
	if err != nil {
		return nil, err
	}

	var keystoreFiles []string

	for _, file := range files {
		if strings.HasPrefix(file.Name(), "keystore-") && strings.HasSuffix(file.Name(), ".json") {
			keystoreFiles = append(keystoreFiles, filepath.Join(folderPath, file.Name()))
		}
	}

	return keystoreFiles, nil
}

func getSecretNameFromKeystoreFile(keystoreFile string) string {
	// Extract the index from the keystore file name, e.g., "keystore-0.json"
	index := strings.TrimPrefix(filepath.Base(keystoreFile), "keystore-")
	index = strings.TrimSuffix(index, ".json")
	return fmt.Sprintf("validator%s", index)
}

func getYAMLFileName(keystoreFile string) string {
	// Construct the YAML file name based on the keystore file name
	return strings.TrimSuffix(keystoreFile, ".json") + ".yaml"
}
