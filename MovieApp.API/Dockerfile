FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files first for a cache-friendly restore layer
COPY MovieApp.sln .
COPY MovieApp.Domain/MovieApp.Domain.csproj MovieApp.Domain/
COPY MovieApp.Application/MovieApp.Application.csproj MovieApp.Application/
COPY MovieApp.Infrastructure/MovieApp.Infrastructure.csproj MovieApp.Infrastructure/
COPY MovieApp.API/MovieApp.API.csproj MovieApp.API/

RUN dotnet restore MovieApp.API/MovieApp.API.csproj

# Copy source and publish
COPY MovieApp.Domain/ MovieApp.Domain/
COPY MovieApp.Application/ MovieApp.Application/
COPY MovieApp.Infrastructure/ MovieApp.Infrastructure/
COPY MovieApp.API/ MovieApp.API/

RUN dotnet publish MovieApp.API/MovieApp.API.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "MovieApp.API.dll"]
