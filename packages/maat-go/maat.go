package maat

// Maat é o ponto de entrada público do SDK Go.
//
// Exemplo de uso:
//
//	client := NewMaatClient()
//	defer client.Disconnect()
//	if err := client.Connect("localhost", 9222, "/"); err != nil {
//	    log.Fatal(err)
//	}
//	result, err := client.Launch(LaunchOptions{
//	    Name: Chromium,
//	})
