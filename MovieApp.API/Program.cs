using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using MovieApp.API.Endpoints;
using MovieApp.Application.Exceptions;
using MovieApp.Infrastructure;
using Serilog;
using Serilog.Sinks.Elasticsearch;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Host.UseSerilog((ctx, _, config) =>
    {
        var esUrl = ctx.Configuration["Elasticsearch:Url"] ?? "http://localhost:9200";

        config
            .Enrich.FromLogContext()
            .Enrich.WithProperty("Application", "MovieApp.API")
            .WriteTo.Console()
            .WriteTo.Elasticsearch(new ElasticsearchSinkOptions(new Uri(esUrl))
            {
                IndexFormat = "movieapp-logs-{0:yyyy.MM.dd}",
                AutoRegisterTemplate = true,
                AutoRegisterTemplateVersion = AutoRegisterTemplateVersion.ESv8
            });
    });

    builder.Services.AddOpenApi();
    builder.Services.AddCors(options =>
        options.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

    builder.Services.AddInfrastructure(builder.Configuration);

    var jwtSection = builder.Configuration.GetSection("Jwt");
    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(opts =>
        {
            opts.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = jwtSection["Issuer"],
                ValidAudience = jwtSection["Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtSection["Key"]!))
            };
        });
    builder.Services.AddAuthorization();

    var app = builder.Build();

    app.Services.ApplyMigrations();

    app.UseExceptionHandler(errApp => errApp.Run(async ctx =>
    {
        var feature = ctx.Features.Get<IExceptionHandlerFeature>();
        var logger = ctx.RequestServices.GetRequiredService<ILogger<Program>>();

        var (statusCode, message) = feature?.Error switch
        {
            ConflictException ex     => (StatusCodes.Status409Conflict, ex.Message),
            NotFoundException ex     => (StatusCodes.Status404NotFound, ex.Message),
            UnauthorizedException ex => (StatusCodes.Status401Unauthorized, ex.Message),
            _                        => (StatusCodes.Status500InternalServerError, "Internal server error")
        };

        if (statusCode == 500)
            logger.LogError(feature?.Error, "Unhandled exception on {Method} {Path}",
                ctx.Request.Method, ctx.Request.Path);

        ctx.Response.StatusCode = statusCode;
        await ctx.Response.WriteAsJsonAsync(new { message });
    }));

    if (app.Environment.IsDevelopment())
        app.MapOpenApi();

    app.UseCors();
    app.UseSerilogRequestLogging();
    app.UseAuthentication();
    app.UseAuthorization();

    app.MapAuthEndpoints();
    app.MapMovieEndpoints();
    app.MapFavoriteEndpoints();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application failed to start");
}
finally
{
    Log.CloseAndFlush();
}
