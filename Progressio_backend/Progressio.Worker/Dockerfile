FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Progressio.Model/Progressio.Model.csproj Progressio.Model/
COPY Progressio.Commom.Services/Progressio.Commom.Services.csproj Progressio.Commom.Services/
COPY Progressio.Services/Progressio.Services.csproj Progressio.Services/
COPY Progressio.Worker/Progressio.Worker.csproj Progressio.Worker/

RUN dotnet restore Progressio.Worker/Progressio.Worker.csproj

COPY . .

RUN dotnet publish Progressio.Worker/Progressio.Worker.csproj \
    -c Release -o /app/publish --no-restore

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Progressio.Worker.dll"]