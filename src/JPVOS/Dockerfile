# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY JPVOS.csproj ./
RUN dotnet restore JPVOS.csproj

# Copy remaining source
COPY . .

# Build and publish (--no-restore since restore already ran)
RUN dotnet publish JPVOS.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Use non-root user for security (built-in .NET 8 user)
USER $APP_UID

# Copy published app
COPY --from=build /app/publish .

# Expose port (container platforms typically assign their own port)
EXPOSE 8080

# Configure ASP.NET Core to listen on all interfaces
# The app will use PORT env var if set by platform, otherwise defaults to 8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Note: Container platforms (Render, Railway, Fly.io) provide their own health checks.
# The /health endpoint is available for platform health probes.

# Use shell form to allow PORT variable expansion at runtime
CMD ["sh", "-c", "dotnet JPVOS.dll --urls http://+:${PORT:-8080}"]
