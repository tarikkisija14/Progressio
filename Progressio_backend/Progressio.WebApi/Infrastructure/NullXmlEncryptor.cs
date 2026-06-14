using Microsoft.AspNetCore.DataProtection.XmlEncryption;
using System.Xml.Linq;

namespace Progressio.WebApi.Infrastructure
{
   
    public class NullXmlEncryptor : IXmlEncryptor
    {
        public EncryptedXmlInfo Encrypt(XElement plaintextElement)
        {
           
            var wrapper = new XElement("encryptedKey",
                new XComment("NullEncryptor — zaštićeno Docker volumeom"),
                plaintextElement);

            return new EncryptedXmlInfo(wrapper, typeof(NullXmlDecryptor));
        }
    }

    public class NullXmlDecryptor : IXmlDecryptor
    {
        public XElement Decrypt(XElement encryptedElement)
        {
           
            return encryptedElement.Elements().First();
        }
    }
}