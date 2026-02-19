export async function handler(request: Request) {
  const response = await fetch(
    "https://" + new URL(request.url).host + "/index.html"
  );
  return new Response(response.body, {
    headers: { "Content-Type": "text/html" },
  });
}