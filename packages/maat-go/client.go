package maat

import (
	"context"
	"encoding/json"
	"fmt"
)

// Request é a mensagem de requisição enviada ao servidor Maat.
type Request struct {
	ID     uint64                 `json:"id"`
	Method string                 `json:"method"`
	Params map[string]interface{} `json:"params,omitempty"`
}

// Response é a mensagem de resposta recebida do servidor Maat.
type Response struct {
	ID     uint64          `json:"id"`
	Result json.RawMessage `json:"result,omitempty"`
	Error  json.RawMessage `json:"error,omitempty"`
}

// MaatClient é o cliente principal do Maat (Go).
type MaatClient struct {
	baseURL   string
	nextID    uint64
	connected bool
	apiKey    string
}

// NewMaatClient cria um cliente não conectado.
func NewMaatClient() *MaatClient {
	return &MaatClient{
		nextID:    1,
		connected: false,
		apiKey:    "",
	}
}

// Connect conecta ao servidor Maat via WebSocket.
// api_key é uma chave de API opcional para autenticação (ativa WSS quando fornecida).
func (c *MaatClient) Connect(host string, port int, path string, apiKey ...string) error {
    scheme := "ws"
    if len(apiKey) > 0 && apiKey[0] != "" {
        scheme = "wss"
        c.apiKey = apiKey[0]
    }
    c.baseURL = fmt.Sprintf("%s://%s:%d%s", scheme, host, port, path)
    c.connected = true
    return nil
}

// ConnectWS conecta usando uma URL WebSocket já resolvida.
func (c *MaatClient) ConnectWS(wsURL string) error {
	c.baseURL = wsURL
	c.connected = true
	return nil
}

// IsConnected retorna se o cliente está conectado.
func (c *MaatClient) IsConnected() bool {
	return c.connected
}

// Disconnect fecha a conexão.
func (c *MaatClient) Disconnect() {
	c.connected = false
	c.baseURL = ""
}

func (c *MaatClient) nextRequestID() uint64 {
	id := c.nextID
	c.nextID++
	return id
}

func buildParams(entries map[string]interface{}) map[string]interface{} {
	return entries
}

// -----------------------------------------------------------------------
// Navegador
// -----------------------------------------------------------------------

// Launch lança um navegador.
func (c *MaatClient) Launch(options LaunchOptions) (*LaunchResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	if options.Security != nil && options.Security.Sandbox {
		// sandbox ativo por padrão; o servidor Zig aplica
	}

	params := map[string]interface{}{
		"name": string(options.Name),
	}
	if options.Protocol != nil {
		params["protocol"] = string(*options.Protocol)
	}
	if options.Headless != nil {
		params["headless"] = *options.Headless
	}
	if len(options.Args) > 0 {
		params["args"] = options.Args
	}
	if options.ExecutablePath != "" {
		sec := &Security{}
		if !sec.IsValidPath(options.ExecutablePath) {
			return nil, NewInvalidPathError(options.ExecutablePath)
		}
		params["executable_path"] = options.ExecutablePath
	}

	// TODO: substituir por chamada WebSocket real quando o servidor Zig expor o endpoint.
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// CloseBrowser fecha o navegador.
func (c *MaatClient) CloseBrowser(browserID string) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// -----------------------------------------------------------------------
// Contexto / Página
// -----------------------------------------------------------------------

// NewContext cria um novo contexto de navegação.
func (c *MaatClient) NewContext(browserID string, options BrowserContextOptions) (*PageResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// NewPage abre uma nova página.
func (c *MaatClient) NewPage(options PageOptions) (*PageResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidURL(options.URL) {
		return nil, NewInvalidUrlError(options.URL)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// ClosePage fecha uma página.
func (c *MaatClient) ClosePage(pageID string) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// -----------------------------------------------------------------------
// Ações na página
// -----------------------------------------------------------------------

// Goto navega para uma URL.
func (c *MaatClient) Goto(pageID, url string) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidURL(url) {
		return nil, NewInvalidUrlError(url)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// Click clica em um seletor.
func (c *MaatClient) Click(pageID string, options ClickOptions) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidSelector(options.Selector) {
		return nil, NewInvalidSelectorError(options.Selector)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// Fill preenche um campo.
func (c *MaatClient) Fill(pageID string, options FillOptions) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidSelector(options.Selector) {
		return nil, NewInvalidSelectorError(options.Selector)
	}
	if !sec.IsValidValue(options.Value) {
		return nil, NewValueTooLongError("value", MaxValueLength)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// Press pressiona uma tecla.
func (c *MaatClient) Press(pageID string, options PressOptions) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidKey(options.Key) {
		return nil, NewInvalidKeyError(options.Key)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// Screenshot tira um screenshot.
func (c *MaatClient) Screenshot(pageID string, options ScreenshotOptions) (*ActionResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	sec := &Security{}
	if !sec.IsValidPath(options.Path) {
		return nil, NewInvalidPathError(options.Path)
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// Title obtém o título da página.
func (c *MaatClient) Title(pageID string) (*TitleResult, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}
	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}

// call envia uma requisição genérica ao servidor Maat.
func (c *MaatClient) call(ctx context.Context, method string, params map[string]interface{}) (*Response, error) {
	if !c.connected {
		return nil, NewNotConnectedError()
	}

	id := c.nextRequestID()
	req := Request{
		ID:     id,
		Method: method,
		Params: params,
	}

	payload, err := json.Marshal(req)
	if err != nil {
		return nil, NewTransportError(err.Error())
	}

	_ = payload
	_ = ctx

	return nil, NewTransportError("WebSocket transport not yet bound to Maat Zig server")
}
