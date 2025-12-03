FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# restore first to leverage layer caching
COPY IMASS.csproj .
RUN dotnet restore IMASS.csproj

# copy the rest of the source
COPY . .
RUN dotnet publish IMASS.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:5103
COPY --from=build /app/publish .
EXPOSE 5103
ENTRYPOINT ["dotnet", "IMASS.dll"]
