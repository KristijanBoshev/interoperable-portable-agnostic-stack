# =========================
# Build stage
# Uses the complete alpine .NET SDK version for smaller image size
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src

# Copy only the project file first to leverage Docker layer caching
COPY ["src/TodoApi.csproj", "./"]
RUN dotnet restore "TodoApi.csproj" --disable-parallel

# Copy the remaining source code
COPY ["src/", "./"]

RUN dotnet publish "TodoApi.csproj" -c Release -o /app/publish

# =========================
# Runtime stage
# Uses the complete alpine ASP.NET runtime image for production
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

WORKDIR /app

# Create a non-root user to run the application
# Prevents running the application as root
RUN adduser -u 5678 --disabled-password --gecos "" appuser


# Copy the published output from the build stage
# Set ownership to the non-root user
COPY --from=build --chown=appuser:appuser /app/publish .

USER appuser

# Expose only port for HTTP. HTTPS will be terminated by a reverse proxy in production. 
ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000

ENTRYPOINT ["dotnet", "TodoApi.dll"]