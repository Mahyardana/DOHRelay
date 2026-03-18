using Microsoft.AspNetCore.Mvc;
using System.Net.Http.Headers;

namespace DOHRelay.Controllers
{
    [ApiController]
    public class DOHController : ControllerBase
    {
        private readonly IHttpClientFactory _httpClientFactory;

        public DOHController(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
        }

        [HttpGet("dns-query")]
        public async Task<FileContentResult> Get([FromQuery] string dns)
        {
            var client = _httpClientFactory.CreateClient("cloudflare-doh");
            var response = await client.GetByteArrayAsync("https://one.one.one.one/dns-query?dns=" + dns);
            return new FileContentResult(response, "application/dns-message");
        }

        [HttpPost("dns-query")]
        public async Task<FileContentResult> Post()
        {
            var body = await new BinaryReader(Request.Body).BaseStream.ReadAllBytesAsync();
            var content = new ByteArrayContent(body);
            content.Headers.ContentType = new MediaTypeHeaderValue("application/dns-message");

            var client = _httpClientFactory.CreateClient("cloudflare-doh");
            var response = await client.PostAsync("https://one.one.one.one/dns-query", content);
            var respBytes = await response.Content.ReadAsByteArrayAsync();
            return new FileContentResult(respBytes, "application/dns-message");
        }
    }

    internal static class StreamExtensions
    {
        internal static async Task<byte[]> ReadAllBytesAsync(this Stream stream)
        {
            using var ms = new MemoryStream();
            await stream.CopyToAsync(ms);
            return ms.ToArray();
        }
    }
}
