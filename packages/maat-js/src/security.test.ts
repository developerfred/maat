/**
 * Testes de segurança para o Maat SDK
 */
import { Security } from './security';

describe('Security Validation', () => {
  describe('isValidUrl', () => {
    it('deve aceitar URLs HTTP válidas', () => {
      expect(Security.isValidUrl('http://example.com')).toBe(true);
      expect(Security.isValidUrl('http://example.com/page.html')).toBe(true);
    });

    it('deve aceitar URLs HTTPS válidas', () => {
      expect(Security.isValidUrl('https://example.com')).toBe(true);
      expect(Security.isValidUrl('https://example.com/page.html?param=value')).toBe(true);
    });

    it('deve rejeitar URLs inválidas', () => {
      expect(Security.isValidUrl('')).toBe(false);
      expect(Security.isValidUrl('ftp://example.com')).toBe(false);
      expect(Security.isValidUrl('javascript:alert(1)')).toBe(false);
      expect(Security.isValidUrl('file:///etc/passwd')).toBe(false);
    });

    it('deve rejeitar URLs com caracteres perigosos', () => {
      expect(Security.isValidUrl('http://example.com/<script>')).toBe(false);
      expect(Security.isValidUrl('http://example.com/?x=<script>')).toBe(false);
    });
  });

  describe('isValidSelector', () => {
    it('deve aceitar seletores válidos', () => {
      expect(Security.isValidSelector('button.submit')).toBe(true);
      expect(Security.isValidSelector('#myId')).toBe(true);
      expect(Security.isValidSelector('.myClass')).toBe(true);
      expect(Security.isValidSelector('div.container.item')).toBe(true);
    });

    it('deve rejeitar seletores perigosos', () => {
      expect(Security.isValidSelector('<script>alert(1)</script>')).toBe(false);
      expect(Security.isValidSelector('"><script>alert(1)</script>')).toBe(false);
    });
  });

  describe('isValidKey', () => {
    it('deve aceitar teclas válidas', () => {
      expect(Security.isValidKey('Enter')).toBe(true);
      expect(Security.isValidKey('Tab')).toBe(true);
      expect(Security.isValidKey('Escape')).toBe(true);
      expect(Security.isValidKey('A')).toBe(true);
      expect(Security.isValidKey('1')).toBe(true);
    });

    it('deve rejeitar teclas inválidas', () => {
      expect(Security.isValidKey('<script>alert(1)</script>')).toBe(false);
      expect(Security.isValidKey('')).toBe(false);
    });
  });

  describe('isValidExpression', () => {
    it('deve aceitar expressões válidas', () => {
      expect(Security.isValidExpression('document.title')).toBe(true);
      expect(Security.isValidExpression('document.getElementById("test")')).toBe(true);
    });

    it('deve rejeitar expressões perigosas', () => {
      expect(Security.isValidExpression('eval("alert(1)")')).toBe(false);
      expect(Security.isValidExpression('setTimeout("alert(1)", 1000)')).toBe(false);
    });
  });

  describe('isValidValue', () => {
    it('deve aceitar valores válidos', () => {
      expect(Security.isValidValue('testuser')).toBe(true);
      expect(Security.isValidValue('test@example.com')).toBe(true);
    });

    it('deve rejeitar valores muito longos', () => {
      const longValue = 'a'.repeat(1001);
      expect(Security.isValidValue(longValue)).toBe(false);
    });
  });

  describe('isValidPath', () => {
    it('deve aceitar caminhos válidos', () => {
      expect(Security.isValidPath('screenshot.png')).toBe(true);
      expect(Security.isValidPath('screenshots/test.png')).toBe(true);
    });

    it('deve rejeitar caminhos perigosos', () => {
      expect(Security.isValidPath('../etc/passwd')).toBe(false);
      expect(Security.isValidPath('/etc/passwd')).toBe(false);
    });
  });
});