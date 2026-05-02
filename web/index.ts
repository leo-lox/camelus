export async function handler(request: Request) {
  const url = new URL(request.url);

  if (url.pathname.startsWith("/.well-known/")) {
    const upstreamUrl =
      "https://about.camelus.app" + url.pathname + url.search;
    return fetch(upstreamUrl, request);
  }

  const imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico'];
  const isImage = imageExtensions.some(ext => url.pathname.toLowerCase().endsWith(ext));

  if (isImage) {
    const response = await fetch("https://" + url.host + url.pathname);
    return new Response(response.body, {
      headers: {
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  const response = await fetch(
    "https://" + url.host + "/index.html"
  );
  return new Response(response.body, {
    headers: { "Content-Type": "text/html" },
  });
}
