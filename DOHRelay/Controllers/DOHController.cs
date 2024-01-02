using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http.Headers;
using System.Text;

namespace DOHRelay.Controllers
{
    [ApiController]
    public class DOHController : ControllerBase
    {

        [HttpGet("dns-query")]
        public FileContentResult Get([FromQuery] string dns)
        {
            var response = new WebClient().DownloadData("https://one.one.one.one/dns-query?dns=" + dns);
            return new FileContentResult(response, "application/dns-message");
        }
        [HttpPost("dns-query")]
        public FileContentResult Post()
        {
            var body = new byte[1024];
            Request.Body.ReadAsync(body, 0, Convert.ToInt32(Request.ContentLength)).Wait();
            var content = new ByteArrayContent(body, 0, Convert.ToInt32(Request.ContentLength));
            content.Headers.ContentType = new MediaTypeHeaderValue("application/dns-message");
            var response = new HttpClient().PostAsync("https://one.one.one.one/dns-query", content).Result;
            var respbytes = response.Content.ReadAsByteArrayAsync().Result;
            return new FileContentResult(respbytes, "application/dns-message");
        }
    }
}
