# Base runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000

# Build stage with SDK
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["IMASS.csproj", "./"]
RUN dotnet restore "IMASS.csproj"
COPY . .
RUN dotnet build "IMASS.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "IMASS.csproj" -c Release -o /app/publish

# Final runtime image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "IMASS.dll"]
