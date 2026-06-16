var builder = DistributedApplication.CreateBuilder(args);

builder.AddContainer("hello-world", "registry.access.redhat.com/hi/core-runtime:latest-builder")
    .WithEntrypoint("sh")
    .WithArgs("-c", "echo hello world && sleep 3600");

builder.Build().Run();
