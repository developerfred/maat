/**
 * Maat CLI - linha de comando para automação de navegador.
 *
 * Consome o SDK maat-rs e expõe subcomandos para lançar navegador,
 * navegar, clicar, preencher campos, tirar screenshot e obter título.
 *
 * Uso exemplos:
 *   maat-cli launch --browser chromium --headless
 *   maat-cli goto --page <id> --url https://example.com
 *   maat-cli click --page <id> --selector button.submit
 *   maat-cli screenshot --page <id> --path screenshot.png
 */

use clap::{Parser, Subcommand};
use maat_rs::{
    BrowserContextOptions, BrowserName, ClickOptions, FillOptions, LaunchOptions, PageOptions,
    PressOptions, ScreenshotOptions, WaitUntil,
};
use maat_rs::{MaatClient, Result};
use std::process::exit;
use tracing::{error, info};
use tracing_subscriber::{EnvFilter, FmtSubscriber};

#[derive(Parser, Debug)]
#[command(name = "maat-cli")]
#[command(about = "Maat - browser automation CLI (sandbox enabled by default)")]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(long, global = true, default_value = "localhost")]
    host: String,

    #[arg(long, global = true, default_value_t = 9222)]
    port: u16,

    #[arg(long, global = true, default_value = "/")]
    path: String,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Lança um navegador.
    Launch {
        #[arg(long, default_value = "chromium")]
        browser: String,

        #[arg(long, default_value_t = false)]
        headless: bool,

        #[arg(long, default_value_t = true)]
        sandbox: bool,

        #[arg(long)]
        executable_path: Option<String>,
    },

    /// Fecha o navegador.
    CloseBrowser {
        #[arg(long)]
        browser_id: String,
    },

    /// Cria um novo contexto de navegação.
    NewContext {
        #[arg(long)]
        browser_id: String,

        #[arg(long, default_value_t = true)]
        sandbox: bool,
    },

    /// Abre uma nova página.
    NewPage {
        #[arg(long)]
        url: String,

        #[arg(long, default_value = "load")]
        wait_until: String,
    },

    /// Fecha uma página.
    ClosePage {
        #[arg(long)]
        page_id: String,
    },

    /// Navega para uma URL.
    Goto {
        #[arg(long)]
        page_id: String,

        #[arg(long)]
        url: String,
    },

    /// Clica em um seletor.
    Click {
        #[arg(long)]
        page_id: String,

        #[arg(long)]
        selector: String,
    },

    /// Preenche um campo.
    Fill {
        #[arg(long)]
        page_id: String,

        #[arg(long)]
        selector: String,

        #[arg(long)]
        value: String,
    },

    /// Pressiona uma tecla.
    Press {
        #[arg(long)]
        page_id: String,

        #[arg(long)]
        key: String,
    },

    /// Tira um screenshot.
    Screenshot {
        #[arg(long)]
        page_id: String,

        #[arg(long)]
        path: String,

        #[arg(long, default_value_t = false)]
        full_page: bool,
    },

    /// Obtém o título da página.
    Title {
        #[arg(long)]
        page_id: String,
    },
}

#[tokio::main]
async fn main() {
    let subscriber = FmtSubscriber::builder()
        .with_env_filter(EnvFilter::from_default_env())
        .finish();
    let _ = tracing::subscriber::set_global_default(subscriber);

    let cli = Cli::parse();

    if let Err(e) = run(cli).await {
        error!("{}", e);
        exit(1);
    }
}

async fn run(cli: Cli) -> Result<()> {
    let mut client = MaatClient::new();
    client
        .connect(&cli.host, cli.port, &cli.path)
        .await
        .map_err(|e| maat_rs::MaatError::Transport { detail: e.to_string() })?;
    info!("Conectado ao servidor Maat em {}:{}{}", cli.host, cli.port, cli.path);

    match cli.command {
        Commands::Launch {
            browser,
            headless,
            sandbox,
            executable_path,
        } => {
            let name = parse_browser_name(&browser)?;
            let options = LaunchOptions {
                name,
                protocol: None,
                headless: Some(headless),
                security: Some(maat_rs::SecurityConfig { sandbox }),
                args: None,
                executable_path,
            };
            let result = client.launch(&options).await?;
            println!("Navegador lançado: id={}", result.browser_id);
            if let Some(ws) = result.ws_url {
                println!("  ws_url: {}", ws);
            }
        }
        Commands::CloseBrowser { browser_id } => {
            let result = client.close_browser(&browser_id).await?;
            println!("Navegador fechado: ok={}", result.ok);
        }
        Commands::NewContext { browser_id, sandbox } => {
            let options = BrowserContextOptions {
                sandbox: Some(sandbox),
            };
            let result = client.new_context(&browser_id, &options).await?;
            println!("Contexto criado: page_id={}", result.page_id);
        }
        Commands::NewPage { url, wait_until } => {
            let wait = parse_wait_until(&wait_until)?;
            let options = PageOptions {
                url,
                wait_until: Some(wait),
            };
            let result = client.new_page(&options).await?;
            println!("Página aberta: page_id={}", result.page_id);
        }
        Commands::ClosePage { page_id } => {
            let result = client.close_page(&page_id).await?;
            println!("Página fechada: ok={}", result.ok);
        }
        Commands::Goto { page_id, url } => {
            let result = client.goto(&page_id, &url).await?;
            println!("Navegação para {}: ok={}", url, result.ok);
        }
        Commands::Click { page_id, selector } => {
            let options = ClickOptions { selector };
            let result = client.click(&page_id, &options).await?;
            println!("Clique em {}: ok={}", options.selector, result.ok);
        }
        Commands::Fill {
            page_id,
            selector,
            value,
        } => {
            let options = FillOptions { selector, value };
            let result = client.fill(&page_id, &options).await?;
            println!(
                "Preenchido {}: ok={}",
                options.selector, result.ok
            );
        }
        Commands::Press { page_id, key } => {
            let options = PressOptions { key };
            let result = client.press(&page_id, &options).await?;
            println!("Tecla {} pressionada: ok={}", options.key, result.ok);
        }
        Commands::Screenshot {
            page_id,
            path,
            full_page,
        } => {
            let options = ScreenshotOptions {
                path,
                full_page: Some(full_page),
            };
            let result = client.screenshot(&page_id, &options).await?;
            println!("Screenshot salvo: ok={}", result.ok);
        }
        Commands::Title { page_id } => {
            let result = client.title(&page_id).await?;
            println!("Título: {}", result.title);
        }
    }

    Ok(())
}

fn parse_browser_name(value: &str) -> Result<BrowserName> {
    match value.to_lowercase().as_str() {
        "chromium" => Ok(BrowserName::Chromium),
        "firefox" => Ok(BrowserName::Firefox),
        "webkit" => Ok(BrowserName::Webkit),
        _ => Err(maat_rs::MaatError::Other {
            message: format!("Navegador não suportado: {}", value),
        }),
    }
}

fn parse_wait_until(value: &str) -> Result<WaitUntil> {
    match value.to_lowercase().as_str() {
        "load" => Ok(WaitUntil::Load),
        "domcontentloaded" => Ok(WaitUntil::Domcontentloaded),
        "networkidle" => Ok(WaitUntil::Networkidle),
        _ => Err(maat_rs::MaatError::Other {
            message: format!("wait_until não suportado: {}", value),
        }),
    }
}
