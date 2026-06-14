FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Progressio.Model/Progressio.Model.csproj Progressio.Model/
COPY Progressio.Commom.Services/Progressio.Commom.Services.csproj Progressio.Commom.Services/
COPY Progressio.Services/Progressio.Services.csproj Progressio.Services/
COPY Progressio.WebApi/Progressio.WebApi.csproj Progressio.WebApi/

RUN dotnet restore Progressio.WebApi/Progressio.WebApi.csproj

COPY . .

RUN dotnet publish Progressio.WebApi/Progressio.WebApi.csproj \
    -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .


RUN mkdir -p /app/wwwroot/uploads/profiles

ENTRYPOINT ["dotnet", "Progressio.WebApi.dll"]
