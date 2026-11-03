/**
 * Maat - TypeScript SDK
 * Tipos compartilhados para automação de navegador
 */

export type BrowserName = 'chromium' | 'firefox' | 'webkit';

export type AutomationProtocol = 'cdp' | 'webdriver';

export interface SecurityConfig {
  sandbox: boolean;
}

export interface LaunchOptions {
  name: BrowserName;
  protocol?: AutomationProtocol;
  headless?: boolean;
  security?: SecurityConfig;
  args?: string[];
  executable_path?: string;
}

export interface WaitUntil {
  type: 'load' | 'domcontentloaded' | 'networkidle';
}

export interface PageOptions {
  url: string;
  waitUntil?: 'load' | 'domcontentloaded' | 'networkidle';
}

export interface ClickOptions {
  selector: string;
}

export interface FillOptions {
  selector: string;
  value: string;
}

export interface PressOptions {
  key: string;
}

export interface ScreenshotOptions {
  path: string;
  fullPage?: boolean;
}

export interface BrowserContextOptions {
  sandbox?: boolean;
}

/**
 * Erros de segurança do Maat
 */
export class MaatError extends Error {
  public code: string;

  constructor(message: string, code: string) {
    super(message);
    this.name = 'MaatError';
    this.code = code;
  }
}

export class InvalidUrlError extends MaatError {
  constructor(url: string) {
    super(`URL inválida: ${url}`, 'INVALID_URL');
    this.name = 'InvalidUrlError';
  }
}

export class InvalidSelectorError extends MaatError {
  constructor(selector: string) {
    super(`Seletor inválido: ${selector}`, 'INVALID_SELECTOR');
    this.name = 'InvalidSelectorError';
  }
}

export class InvalidKeyError extends MaatError {
  constructor(key: string) {
    super(`Tecla inválida: ${key}`, 'INVALID_KEY');
    this.name = 'InvalidKeyError';
  }
}

export class ValueTooLongError extends MaatError {
  constructor(field: string, maxLength: number) {
    super(`Valor muito longo para ${field} (máximo ${maxLength} caracteres)`, 'VALUE_TOO_LONG');
    this.name = 'ValueTooLongError';
  }
}

export class ExpressionTooLongError extends MaatError {
  constructor(expressionLength: number, maxLength: number) {
    super(`Expressão muito longa (${expressionLength} caracteres, máximo ${maxLength})`, 'EXPRESSION_TOO_LONG');
    this.name = 'ExpressionTooLongError';
  }
}

export class InvalidPathError extends MaatError {
  constructor(path: string) {
    super(`Caminho inválido: ${path}`, 'INVALID_PATH');
    this.name = 'InvalidPathError';
  }
}