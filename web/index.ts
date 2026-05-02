export async function handler(request: Request) {
  const url = new URL(request.url);

  if (url.pathname.startsWith("/.well-known/")) {
    const upstreamUrl =
      "https://about.camelus.app" + url.pathname + url.search;
    return fetch(upstreamUrl, request);
  }

  const response = await fetch(
    "https://" + url.host + "/index.html"
  );
  return new Response(response.body, {
    headers: { "Content-Type": "text/html" },
  });
}