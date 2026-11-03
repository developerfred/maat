package maat

// BrowserName representa o nome do navegador suportado.
type BrowserName string

const (
	Chromium BrowserName = "chromium"
	Firefox  BrowserName = "firefox"
	Webkit   BrowserName = "webkit"
)

// AutomationProtocol representa o protocolo de automação.
type AutomationProtocol string

const (
	Cdp       AutomationProtocol = "cdp"
	WebDriver AutomationProtocol = "webdriver"
)

// WaitUntil representa a condição de espera ao navegar.
type WaitUntil string

const (
	Load             WaitUntil = "load"
	Domcontentloaded WaitUntil = "domcontentloaded"
	Networkidle      WaitUntil = "networkidle"
)

// SecurityConfig configura segurança do navegador/contexto.
type SecurityConfig struct {
	Sandbox bool
}

// LaunchOptions são as opções de lançamento do navegador.
type LaunchOptions struct {
	Name           BrowserName
	Protocol       *AutomationProtocol
	Headless       *bool
	Security       *SecurityConfig
	Args           []string
	ExecutablePath string
}

// PageOptions são as opções de abertura de página.
type PageOptions struct {
	URL       string
	WaitUntil *WaitUntil
}

// ClickOptions são as opções de clique.
type ClickOptions struct {
	Selector string
}

// FillOptions são as opções de preenchimento de campo.
type FillOptions struct {
	Selector string
	Value    string
}

// PressOptions são as opções de pressionar tecla.
type PressOptions struct {
	Key string
}

// ScreenshotOptions são as opções de screenshot.
type ScreenshotOptions struct {
	Path     string
	FullPage *bool
}

// BrowserContextOptions são as opções de contexto.
type BrowserContextOptions struct {
	Sandbox *bool
}

// LaunchResult é o resultado do lançamento do navegador.
type LaunchResult struct {
	BrowserID string
	WsURL     string
}

// PageResult é o resultado de nova página/contexto.
type PageResult struct {
	PageID    string
	ContextID string
}

// ActionResult é o resultado genérico de ação.
type ActionResult struct {
	Ok    bool
	Value map[string]interface{}
}

// TitleResult é o resultado do título da página.
type TitleResult struct {
	Title string
}
