using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);


builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapHealthChecks("/health");
app.MapHealthChecks("/ready");


app.MapGet("/", () => new
{
    service = "SignIn API",
    version = "1.0.0",
    environment = app.Environment.EnvironmentName,
    timestamp = DateTime.UtcNow
});

// SignIn endpoint
app.MapPost("/api/signin", ([FromBody] SignInRequest request) =>
{
    // Simple validation
    if (string.IsNullOrEmpty(request.Username) || string.IsNullOrEmpty(request.Password))
    {
        return Results.BadRequest(new { error = "Username and password are required" });
    }

    // Mock authentication logic
    if (request.Username == "demo" && request.Password == "password123")
    {
        var token = GenerateToken(request.Username);
        return Results.Ok(new
        {
            success = true,
            token = token,
            username = request.Username,
            expiresIn = 3600
        });
    }

    return Results.Unauthorized();
})
.WithName("SignIn")
.WithOpenApi();

// SignOut endpoint
app.MapPost("/api/signout", ([FromHeader(Name = "Authorization")] string? token) =>
{
    if (string.IsNullOrEmpty(token))
    {
        return Results.BadRequest(new { error = "Token required" });
    }

    return Results.Ok(new { success = true, message = "Signed out successfully" });
})
.WithName("SignOut")
.WithOpenApi();

// User info endpoint
app.MapGet("/api/user", ([FromHeader(Name = "Authorization")] string? token) =>
{
    if (string.IsNullOrEmpty(token))
    {
        return Results.Unauthorized();
    }

    return Results.Ok(new
    {
        username = "demo",
        email = "demo@example.com",
        roles = new[] { "user", "admin" }
    });
})
.WithName("GetUser")
.WithOpenApi();

app.Run();


string GenerateToken(string username)
{
    var randomBytes = System.Security.Cryptography.RandomNumberGenerator.GetBytes(32);
    return Convert.ToBase64String(randomBytes);
}

public record SignInRequest(string Username, string Password);
