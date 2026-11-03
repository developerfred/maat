/**
 * Exemplo de uso do Maat SDK
 * 
 * Este exemplo mostra como usar a API do Maat para automação de navegador.
 */

import { maat } from '../src/index';

async function main() {
  try {
    // 1. Lançar navegador com sandbox ativado por padrão
    const browser = await maat.Browser.launch({
      name: maat.BrowserName.chromium,
      headless: false,
      security: { sandbox: true }
    });

    // 2. Criar uma nova página
    const page = await browser.newPage();

    // 3. Navegar para uma URL
    await page.goto('https://example.com', maat.WaitUntil.load);

    // 4. Clicar em um elemento
    await page.click('button.submit');

    // 5. Preencher um formulário
    await page.fill('input#username', 'testuser');

    // 6. Pressionar uma tecla
    await page.press('Enter');

    // 7. Obter o título da página
    const title = await page.title();
    console.log(`Título da página: ${title}`);

    // 8. Executar JavaScript
    const jsResult = await page.evaluate('document.title');
    console.log(`Resultado JS: ${jsResult}`);

    // 9. Tirar screenshot
    await page.screenshot('resultado.png');

    console.log('Automação concluída com sucesso!');
  } catch (error) {
    console.error('Erro durante a automação:', error);
  }
}

main();