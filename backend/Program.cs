using IMASS.Data;
using IMASS.Models;
using IMASS.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

using IMASS.Hubs;

var builder = WebApplication.CreateBuilder(args);
builder.Services.Configure<FormOptions>(o =>
{
    o.MultipartBodyLengthLimit = 1024L * 1024L * 1024L;
    o.ValueLengthLimit = int.MaxValue;
    o.MemoryBufferThreshold = int.MaxValue;
});
// Add services to the container.
builder.Services.AddHttpClient<IFasstApiService, FasstApiService>();
builder.Services.AddScoped<FasstApiService>();
builder.Services.AddScoped<IScenarioBuilder, ScenarioBuilder>();
builder.Services.AddScoped<IModelRunner, ModelRunner>();
//Connection to PostgresSql
builder.Services.AddDbContext<ApplicationDbContext>(options => options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection")

    ));


// For Identity
builder.Services.AddIdentity<ApplicationUser,IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

//Add CORS policy
builder.Services.AddCors(opt =>
{
    opt.AddPolicy("frontend", p =>
        p
        .WithOrigins("http://localhost:5173", "http://localhost:4200", "http://localhost:3000")
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()
    );
});


//JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;

})
    .AddJwtBearer(options =>
    {
        options.SaveToken = true;
        options.RequireHttpsMetadata = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidAudience = builder.Configuration["JWT:ValidAudience"],
            ValidIssuer = builder.Configuration["JWT:ValidIssuer"],
            ClockSkew = TimeSpan.Zero,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["JWT:Secret"]))
        };
    })
    .AddGoogle("Google", options =>
    {
        options.ClientId = builder.Configuration["Google:ClientId"]!;
        options.ClientSecret = builder.Configuration["Google:ClientSecret"]!;
        options.CallbackPath = "/signin-google";
        // Important: tell Google where to store the external principal
        options.SignInScheme = IdentityConstants.ExternalScheme;
    });

builder.Services.AddTransient<ITokenService, TokenService>();


// Add FASST API service
builder.Services.AddHttpClient<IFasstApiService, FasstApiService>();
builder.Services.AddScoped<IFasstApiService, FasstApiService>();
builder.Services.AddHttpClient("FasstHealth", client =>
{
    var baseUrl = builder.Configuration["Fasst:BaseUrl"] ?? "http://localhost:8000";
    client.BaseAddress = new Uri(baseUrl);
    client.Timeout = TimeSpan.FromSeconds(5);
});

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// [SignalR] register the hub services
builder.Services.AddSignalR();
builder.Services.AddHostedService<FasstHealthPublisherService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseCors("frontend");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// [SignalR] map the hub endpoint
app.MapHub<HealthHub>("/hubs/health");

//Seed Admin User if none exists (this comes directly from our DbSeeder class using the function)
await DbSeeder.SeedDataAsync(app);

app.Run();
