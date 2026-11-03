/**
 * Maat - Módulo de Segurança
 * Validações de segurança para prevenir ataques de injeção
 */

export class Security {
  public static MaxUrlLength = 2048;
  public static MaxSelectorLength = 256;
  public static MaxKeyLength = 32;
  public static MaxExpressionLength = 1000;
  public static MaxValueLength = 1000;

  private static DangerousUrlChars = ['<', '>', '"', '\'', '&', ';', '|', '`', '$', '(', ')', '{', '}',
    '[', ']', '\\', '#', '%', '+', '!', '@', '*', '~'];

  private static DangerousSelectorChars = ['<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
    '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
    ' ', '\t', '\n', '\r'];

  private static DangerousKeyChars = &[_]u8{
    '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
    '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
    ' ', '\t', '\n', '\r',
  };

  public static isValidUrl(url: string): boolean {
    if (!url || url.length === 0 || url.length > Security.MaxUrlLength) return false;

    // Decodifica percent-encoding antes de validar (previne bypass por encoding)
    let decoded: string;
    try {
      decoded = decodeURIComponent(url);
    } catch {
      return false; // URL malformada
    }

    if (!decoded.startsWith('http://') && !decoded.startsWith('https://')) {
      return false;
    }

    for (const char of Security.DangerousUrlChars) {
      if (decoded.includes(char)) return false;
    }

    return true;
  }

  public static isValidSelector(selector: string): boolean {
    if (!selector || selector.length === 0 || selector.length > Security.MaxSelectorLength) return false;

    for (const char of Security.DangerousSelectorChars) {
      if (selector.includes(char)) return false;
    }

    return true;
  }

  public static isValidKey(key: string): boolean {
    if (!key || key.length === 0 || key.length > Security.MaxKeyLength) return false;

    const validPattern = /^[a-zA-Z0-9_\-\.]+$/;
    return validPattern.test(key);
  }

  public static isValidExpression(expression: string): boolean {
    if (!expression || expression.length === 0 || expression.length > Security.MaxExpressionLength) return false;

    const dangerousPatterns = [
      'eval(', 'setTimeout(', 'setInterval(', 'Function(',
      'document.write(', 'document.writeln(', 'innerHTML',
      'outerHTML', 'document.cookie', 'localStorage',
      'sessionStorage', 'XMLHttpRequest', 'fetch(',
      'location.href', 'location.replace', 'location.assign',
    ];

    for (const pattern of dangerousPatterns) {
      if (expression.includes(pattern)) return false;
    }

    const dangerousChars = ['<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
      '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\'];

    for (const char of dangerousChars) {
      if (expression.includes(char)) return false;
    }

    return true;
  }

  public static isValidValue(value: string): boolean {
    if (!value || value.length === 0 || value.length > Security.MaxValueLength) return false;
    return true;
  }

  public static isValidPath(path: string): boolean {
    if (!path || path.length === 0 || path.length > Security.MaxUrlLength) return false;
    if (path.includes('../')) return false;
    if (path.startsWith('/')) return false;
    return true;
  }

  public static sanitize(input: string): string {
    let result = '';
    for (const c of input) {
      if (c === '<' || c == '>' || c == '"' || c == '\'') {
        continue;
      }
      result += c;
    }
    return result;
  }
}

export default Security;