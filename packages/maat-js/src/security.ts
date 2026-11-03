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

  /// Padrões de path traversal perigosos (após decodificação).
  private static PathTraversalPatterns = ['../', '..\\', '..%2f', '..%5c', '..%252f', '..%255c'];

  /// Decodifica percent-encoding incluindo duplo encoding.
  private static decodePercentEncodingFull(input: string): string {
    let decoded: string;
    try {
      decoded = decodeURIComponent(input);
    } catch {
      return input; // URL malformada, retorna original
    }
    // Se ainda houver % após decodificação, tenta novamente (duplo encoding)
    if (decoded.includes('%')) {
      try {
        return decodeURIComponent(decoded);
      } catch {
        return decoded;
      }
    }
    return decoded;
  }

  /// Verifica se o caminho contém padrões de path traversal.
  private static containsPathTraversal(path: string): boolean {
    const lower = path.toLowerCase();
    return Security.PathTraversalPatterns.some(p => lower.includes(p));
  }

  public static isValidUrl(url: string): boolean {
    if (!url || url.length === 0 || url.length > Security.MaxUrlLength) return false;

    // Decodifica percent-encoding antes de validar (previne bypass por encoding)
    const decoded = Security.decodePercentEncodingFull(url);

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

    // Decodifica percent-encoding para detectar path traversal ofuscado
    const decoded = Security.decodePercentEncodingFull(path);

    // Bloqueia path traversal (simples e ofuscado por encoding)
    if (Security.containsPathTraversal(decoded)) return false;

    // Bloqueia caminhos absolutos
    if (decoded.startsWith('/') || decoded.startsWith('\\')) return false;

    // Bloqueia links simbólicos e caminhos de unidade Windows
    if (decoded.startsWith('~') || (decoded.length >= 2 && decoded[1] === ':')) return false;

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