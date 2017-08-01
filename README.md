[![Godoc Reference](https://godoc.org/github.com/minio/highwayhash?status.svg)](https://godoc.org/github.com/minio/highwayhash)
[![Build Status](https://travis-ci.org/minio/highwayhash.svg?branch=master)](https://travis-ci.org/minio/highwayhash)

## HighwayHash

HighwayHash is a pseudo-random-function (PRF) developed by Jyrki Alakuijala, Bill Cox and Jan Wassenberg (Google research).
HighwayHash takes a 256 bit key and computes 64, 128 or 256 bit hash values of given messages. It can be used to prevent hash-flooding
attacks or authenticate short-lived messages. It can also be used as a fingerprint function.
This repository provides a native Go and optimized assembly implementations for the AMD64 and ARM64 platforms.  

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

Platform/CPU      | Write 64            | Write 1024           | Sum 64 / cpb        | Sum 1024
----------------- | ------------------- | -------------------- | ------------------- | ------------------- 
AMD64 AVX2        | 4.66GB/s / 0.50 cpb | 10.6GB/s / 0.22 cpb  | 1.75GB/s / 1.33 cpb | 8.46GB/s / 0,28 cpb
AMD64 SSE4.1      | 3.42GB/s / 0.68 cpb | 8.39GB/s / 0.28 cpb  | 1.29GB/s / 1.81 cpb | 6.69GB/s / 0.35 cpb


**Hardware:**  
Intel i7-6500U 2.50GHz x 2 | Ubuntu 16.04 - kernel: 4.10.0-28-generic | Go: 1.8.3  
