[![Godoc Reference](https://godoc.org/github.com/minio/highwayhash?status.svg)](https://godoc.org/github.com/minio/highwayhash)
[![Build Status](https://travis-ci.org/minio/highwayhash.svg?branch=master)](https://travis-ci.org/minio/highwayhash)

## HighwayHash

HighwayHash is a pseudo-random-function (PRF) developed by Jyrki Alakuijala, Bill Cox and Jan Wassenberg (Google research).
HighwayHash takes a 256 bit key and computes 64, 128 or 256 bit hash values of given messages. It can be used to prevent hash-flooding
attacks or authenticate short-lived messages. It can also be used as a fingerprint function.
This repository provides a native Go and specialist assembly implementations for the AMD64 and ARM64 platforms.  

HighwayHash is not a general purpose cryptographic hash function (like BLAKE2b, SHA-3, SHA-2,...) and cannot be used if (strong) collision
resistance is required. 

### Attention
HighwayHash is not finalized and may change. You should not use HighwayHash in your project until the authors publish a final version.

### Installation

Install: `go get -u github.com/minio/highwayhash`

### Requirements

All Go versions >= 1.7 are supported.
Notice that the amd64 AVX2 implementation is only available with Go 1.8 and newer.

### Performance

**AMD64**
Hardware: Intel i7-6500U 2.50GHz x 2  
System: Linux Ubuntu 16.04 - kernel: 4.10.0-28-generic  
Go version: 1.8.3  
```
AVX2
name         speed           cpb
Write_64-4   4.64GB/s ± 0%    0.50
Write_1K-4   10.6GB/s ± 0%    0.22
Write_8K-4   11.7GB/s ± 0%    0.20
Sum64_8-4     127MB/s ± 0%   18.77
Sum64_16-4    240MB/s ± 1%    9.93
Sum64_64-4   1.54GB/s ± 0%    1.51
Sum64_1K-4   8.13GB/s ± 0%    0.29
Sum64_8K-4   11.3GB/s ± 0%    0.21 
Sum256_8-4    111MB/s ± 0%   21.48
Sum256_16-4   211MB/s ± 1%   11.30
Sum256_64-4  1.29GB/s ± 0%    1.81
Sum256_1K-4  7.59GB/s ± 1%    0.31
Sum256_8K-4  11.1GB/s ± 0%    0.21

SSE4.1
name         speed           cpb
Write_64-4   3.42GB/s ± 0%    0.68
Write_1K-4   8.39GB/s ± 0%    0.28
Write_8K-4   9.60GB/s ± 0%    0.24
Sum64_8-4     119MB/s ± 1%   20.04
Sum64_16-4    229MB/s ± 1%   10.41
Sum64_64-4   1.29GB/s ± 0%    1.81
Sum64_1K-4   6.69GB/s ± 0%    0.35
Sum64_8K-4   9.27GB/s ± 0%    0.25
Sum256_8-4    104MB/s ± 0%   22.93
Sum256_16-4   203MB/s ± 0%   11.75
Sum256_64-4  1.08GB/s ± 0%    2.16
Sum256_1K-4  6.35GB/s ± 0%    0.37
Sum256_8K-4  9.17GB/s ± 0%    0.25
```  
