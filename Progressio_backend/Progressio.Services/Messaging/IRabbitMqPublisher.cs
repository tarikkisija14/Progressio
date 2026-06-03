namespace Progressio.Services.Messaging
{
    public interface IRabbitMqPublisher
    {
        
        void Publish<T>(string queueName, T message);

        
        Task PublishAsync<T>(string queueName, T message);
    }
}