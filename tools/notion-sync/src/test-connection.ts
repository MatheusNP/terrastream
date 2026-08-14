import { Client } from "@notionhq/client";
import "dotenv/config";

const token = process.env.NOTION_TOKEN;
const pageId = process.env.NOTION_TEST_PAGE_ID;

if (!token || !pageId) {
  console.error("Faltando NOTION_TOKEN ou NOTION_TEST_PAGE_ID no .env");
  process.exit(1);
}

const notion = new Client({ auth: token });

async function main() {
  console.log("Testando leitura da página...");
  const page = await notion.pages.retrieve({ page_id: pageId! });
  console.log("✅ Leitura OK. Página encontrada:", (page as any).id);

  console.log("Testando escrita (append de bloco)...");
  await notion.blocks.children.append({
    block_id: pageId!,
    children: [
      {
        object: "block",
        type: "paragraph",
        paragraph: {
          rich_text: [
            {
              type: "text",
              text: {
                content: `✅ Teste de conexão bem-sucedido em ${new Date().toISOString()}`,
              },
            },
          ],
        },
      },
    ],
  });
  console.log("✅ Escrita OK. Confira a página no Notion.");
}

main().catch((err) => {
  console.error("❌ Falhou:", err.body ?? err.message);
  process.exit(1);
});

