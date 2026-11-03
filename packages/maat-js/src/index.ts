/**
 * Maat - Playwright-like browser automation in Zig
 * 
 * API pública para automação de navegador com sandbox ativo por padrão.
 * Segurança em primeiro lugar.
 */

export {
  BrowserName,
  AutomationProtocol,
  SecurityConfig,
  LaunchOptions,
  WaitUntil,
  PageOptions,
  ClickOptions,
  FillOptions,
  PressOptions,
  ScreenshotOptions,
  BrowserContextOptions
} from './types';

export {
  isValidUrl,
  isValidSelector,
  isValidKey,
  isValidExpression,
  isValidValue,
  isValidPath,
  Security
} from './security';

export { CdpClient } from './client';

export {
  MaatError,
  InvalidUrlError,
  InvalidSelectorError,
  InvalidKeyError,
  ValueTooLongError,
  ExpressionTooLongError,
  InvalidPathError
} from './types';