# Stage 1: Build SNTHERM binary

FROM gcc:12 AS build

WORKDIR /src

# Copy Fortran sources and Makefile
COPY fortran-src/ ./fortran-src/

# Replace hardcoded f77 with gfortran in the Makefile
RUN sed -i 's/\bf77\b/gfortran/' fortran-src/Makefile

# Build SNTHERM using gfortran
RUN make -C fortran-src FC=gfortran

# Stage 2: Runtime container
FROM python:3.11-slim

WORKDIR /app

# Install system libs needed for Fortran binaries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgfortran5 \
    libquadmath0 \
 && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Flask app
COPY app.py /app/app.py

# Copy SNTHERM binary from build stage
COPY --from=build /src/fortran-src/sntherm /app/sntherm

# Handle Input Files

# Copy everything from ./data on host → /app/workdir in container
RUN mkdir -p /app/workdir


# Copy and rename test.in → FILENAME so SNTHERM finds it
COPY data/test.in /app/workdir/test.in
COPY data/metswe.in /app/workdir/metswe.in
COPY data/FILENAME /app/workdir/FILENAME

# Expose Flask port
EXPOSE 5000

# Start Flask
CMD ["python", "app.py"]
