package test

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
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

// To run:
// go run main.go <path_to_keystore_file>
// Example: go run main.go /Users/Downloads/keystore-0.json
func main() {
	args := os.Args[1:]
	filename := args[0]
	secretPath := args[1]
	secretName := args[2]
	b, err := os.ReadFile(filename)
	if err != nil {
		log.Fatal(err, "read keystore file")
	}

	err = godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	token := os.Getenv("VAULT_TOKEN")

	var store keystore.Keystore
	err = json.Unmarshal(b, &store)
	if err != nil {
		log.Fatal(err, "unmarshal keystore file")
	}

	password, err := loadPassword(filename)
	if err != nil {
		log.Fatal(err, "load password")
	}

	secret, err := decrypt(store, password)
	if err != nil {
		log.Fatal(err, "decrypt keystore")
	}

	fmt.Printf("Hex encoded private key: %s\n", fmt.Sprintf("%x", secret[:]))

	// Upload the private key to HashiCorp Vault
	err = uploadPrivateKeyToVault(secret, token, secretPath, secretName)
	if err != nil {
		log.Fatal(err, "upload private key to Vault")
	}

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
		KeyPath:    fmt.Sprintf("%s/%s", secretPath, secretName), // Replace with the actual path and name
		KeyName:    "value",
		ServerHost: "vault.vault.svc.cluster.local",
		ServerPort: "8200",
		Timeout:    "10000",
		Token:      `"` + token + `"`,
	}

	// Marshal the struct into YAML format
	yamlBytes, err := yaml.Marshal(&yamlData)
	if err != nil {
		log.Fatal(err, "marshal YAML data")
	}

	// Save the YAML data to a file
	yamlFileName := "keystore.yaml" // Replace with your desired file name

	// Check if the file exists
	var fileExists bool
	if _, err := os.Stat(yamlFileName); err == nil {
		fileExists = true
	}

	fmt.Printf("File exists: %t\n", fileExists)

	// Open the file for writing (create if not exists, append otherwise)
	file, err := os.OpenFile(yamlFileName, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0644)
	if err != nil {
		log.Fatal(err, "open file")
	}
	defer file.Close()

	// Add "---" as a separator if the file already exists or is being created
	if fileExists {
		_, err = file.WriteString("---\n")
		if err != nil {
			log.Fatal(err, "write separator")
		}
	}

	_, err = file.Write(yamlBytes)
	if err != nil {
		log.Fatal(err, "write YAML to file")
	}

	fmt.Printf("YAML data saved to %s\n", yamlFileName)
}

// loadPassword loads a keystore password from the Keystore's associated password file.
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

// decrypt returns the secret from the encrypted (empty password) Keystore.
func decrypt(store keystore.Keystore, password string) (tbls.PrivateKey, error) {
	decryptor := keystorev4.New()
	secretBytes, err := decryptor.Decrypt(store.Crypto, password)
	if err != nil {
		return tbls.PrivateKey{}, errors.Wrap(err, "decrypt keystore")
	}

	return tblsconv.PrivkeyFromBytes(secretBytes)
}

// uploadPrivateKeyToVault uploads the private key to HashiCorp Vault.
func uploadPrivateKeyToVault(privateKey tbls.PrivateKey, token string, secretPath string, secretName string) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()
	// Create a Vault client
	client, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		return errors.Wrap(err, "create Vault client")
	}

	// Authenticate to Vault (assuming you've already logged in)
	// You can set the token using client.SetToken("<your_token>")
	client.SetToken(token)
	// Prepare the private key in the format you want (e.g., as a string)
	privateKeyHex := fmt.Sprintf("%x", privateKey[:])

	// Write the private key to Vault
	//secretPath := "charon-perf-1-node1"
	data := map[string]interface{}{
		"value": privateKeyHex,
	}
	client.Sys().Mount(secretPath, &api.MountInput{
		Type: "kv",
		Options: map[string]string{
			"version": "2",
		},
	})
	//create a kvV2 secret engine
	var kv = client.KVv2(secretPath)
	_, err = kv.Put(ctx, secretName, data)
	if err != nil {
		return errors.Wrap(err, "create Vault client")
	}

	fmt.Println("Private key uploaded to Vault successfully")
	return nil
}
