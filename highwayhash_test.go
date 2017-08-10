// Copyright (c) 2017 Minio Inc. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

package highwayhash

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"hash"
	"testing"
)

func TestVectors(t *testing.T) {
	defer func(sse4, avx2, neon bool) {
		useSSE4, useAVX2, useNEON = sse4, avx2, neon
	}(useSSE4, useAVX2, useNEON)

	if useAVX2 {
		t.Log("AVX2 version")
		testVectors(func(key []byte) (hash.Hash, error) { return New64(key) }, testVectors64, t)
		testVectors(New128, testVectors128, t)
		testVectors(New, testVectors256, t)
		useAVX2 = false
	}
	if useSSE4 {
		t.Log("SSE4 version")
		testVectors(func(key []byte) (hash.Hash, error) { return New64(key) }, testVectors64, t)
		testVectors(New128, testVectors128, t)
		testVectors(New, testVectors256, t)
		useSSE4 = false
	}
	if useNEON {
                t.Log("NEON version")
                testVectors(func(key []byte) (hash.Hash, error) { return New64(key) }, testVectors64, t)
                testVectors(New128, testVectors128, t)
                testVectors(New, testVectors256, t)
                useNEON = false
	}
	t.Log("generic version")
	testVectors(func(key []byte) (hash.Hash, error) { return New64(key) }, testVectors64, t)
	testVectors(New128, testVectors128, t)
	testVectors(New, testVectors256, t)
}

func testVectors(NewFunc func([]byte) (hash.Hash, error), vectors []string, t *testing.T) {
	key, err := hex.DecodeString("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	if err != nil {
		t.Fatalf("Failed to decode key: %v", err)
	}
	input := make([]byte, len(vectors))

	h, err := NewFunc(key[:])
	if err != nil {
		t.Fatalf("Failed to create highwayhash instance:  %v", err)
	}
	for i, v := range vectors {
		input[i] = byte(i)

		expected, err := hex.DecodeString(v)
		if err != nil {
			t.Fatalf("Failed to decode test vector: %v error:  %v", v, err)
		}

		h.Write(input[:i])
		if sum := h.Sum(nil); !bytes.Equal(sum, expected[:]) {
			t.Errorf("Test %d: hash mismatch: got: %v want: %v", i, hex.EncodeToString(sum), hex.EncodeToString(expected))
		}
		h.Reset()

		switch h.Size() {
		case Size:
			if sum := Sum(input[:i], key); !bytes.Equal(sum[:], expected) {
				t.Errorf("Test %d: Sum mismatch: got: %v want: %v", i, hex.EncodeToString(sum[:]), hex.EncodeToString(expected))
			}
		case Size128:
			if sum := Sum128(input[:i], key); !bytes.Equal(sum[:], expected) {
				t.Errorf("Test %d: Sum mismatch: got: %v want: %v", i, hex.EncodeToString(sum[:]), hex.EncodeToString(expected))
			}
		case Size64:
			var sum [Size64]byte
			binary.LittleEndian.PutUint64(sum[:], Sum64(input[:i], key))
			if !bytes.Equal(sum[:], expected) {
				t.Errorf("Test %d: Sum mismatch: got: %v want: %v", i, hex.EncodeToString(sum[:]), hex.EncodeToString(expected))
			}
		}
	}
}

var testVectors64 = []string{
	"536ec222de567a90", "78ddcdc7aa43ab7e", "623db5b09a56d0b8", "803d468aabef6b5c", "da7e009368a405f2", "4145a9e468168a2b", "6fcaef5b32cc4cbd", "8294f53817ae024d",
	"71315fe5085120e1", "84157ac74e64d232", "0ba903b1cd0ae1f6", "155c415b61f4bbc3", "9cfa630004c23c24", "ff41e665ce589aa8", "235a4548a331b024", "3bf349a4863f7940",
	"32b87ef98934abcf", "e2c0c5c8d267fe19", "c25c569ca690dd04", "04c571238e51d975", "16ddd341119bad38", "e0708acd2c436402", "90336888625adba9", "8c023f009254b0d7",
	"1ee559ea5a615f20", "8428052196c8e0ee", "4f4f28a7931afc1b", "1da90db7b5752151", "39c6a2a076891ff7", "e7e3841fef3f09ae", "0f866111b092ca22", "685a03cf7c00c79f",
	"fc80d5ecd964c9a0", "fc8131a03cf7902c", "9eeb91564ef85c18", "9baa5227eff5c14f", "eb330a5e1a39b7f5", "9c6ce9b4834bb8b9", "b4d95c2a71fe425e", "dc973f0cf9f250a1",
	"7d632d5ed722a57f", "2bd3ff0dccd01a18", "2840851e98ed8938", "2dee86c5e89742fb", "9c0528bb454a066d", "0c86ecb309365690", "66c69740e9fca47a", "081e916bc0ba2613",
	"344f152b8d1626b9", "8d94b14589841999", "be5e8234c58fa9a2", "b6f03e21959080e9", "e9c07b7083542e58", "f56a8aa814946e08", "3d74f6208db986ee", "a7c0b109f67f9bf8",
	"e8c3229ec19c7d4c", "6f2a56245000979a", "efebe623f41cd45d", "27e268049c6013df", "5a158841f6a40d6e", "a1d4d7504bba55b7", "bd79746484347a88", "a03921bfe9eb8eab",
	"ffa6d24c5d2c5475",
}

var testVectors128 = []string{
	"7c8ac284e8d179068d7404f94725ca2b", "b997d8c2bc393a7f1fd964a03c117e4a", "bf85abc5924bb36ac2769d6846c57aed", "be7d4a5a40f86aace1c3563295b78fd7",
	"4864b889f78c6e5a18c2ed1b7cf44e83", "a325f473b5e0bf8e5a3284cb10c4fcbc", "d6f1b8ca1797e1a17d871f887106a52a", "eca10d950253590b88b30472e22d9346",
	"d4890f203f03fb02921f423bbbd7c3fe", "deeac16cd479540adec3f1a0d5a2160c", "061162dd1de459f75047006e11703db4", "8fe9a436bc100098d1bb00ae17934727",
	"79a36137b2f3ab3b26f356028ec2cdac", "2e149e2604cd8057a9edbd233fee70bb", "c39ee937191f404a14e2b4d685133d4b", "b02c0e08de6e5c0489dc32215db42773",
	"56171ceb4b62e1972450d4691b7e13b7", "12f00bdbe3a8db31169b728aa7e6663e", "a7f28a5d1bdfd63455eb39bcfc471a4f", "bcdce5472dbec6e21f7c304e2885ffd2",
	"92c88e09061e68dad1fe19503598ad71", "0bc32f1f2bd7fbc4d5edfdc9b6497532", "b50e0fc2d129f41469a33f2fc9408b22", "016d20335353c9f5ccf965cafc46fcb6",
	"2d9d72dbd9fa4930ea81f7451c934cb8", "04dc06376ffe6f7c623cae063858944f", "e0cce18bb25ef99efe5bd1a0965b9dad", "e68529af54edd063011b5c48b6b1afdf",
	"6cd498e42f8a6ca4d6ba03ffc0aedbf4", "58513ebb0f8a97edfde6fb574d140d06", "e5e422890cd8f153c94021930d882413", "ce703856033b36dd4b18344f9fb7fd0d",
	"38db65ae0127704e04fbdbe2a2e0671b", "22081d5588a30d2461bdc44a58bbf12f", "ab9964c2b7b8af3f3291888e30162507", "22ab06943352b40a422d47f97fbb1d75",
	"8611ebb62d78ba8329dc18934d549143", "e801b2aacd7e0725a2636d44950e5e69", "d4171ff912bff01a2cd2689329ffb85b", "381e70afcb098c3378dc067c5e4dd2a7",
	"568bd255658db55a0f31e19a3a4181e7", "897bca0bd11c28b074720f5cb47398f4", "067be5716dbdee67dfed4eb51dcb2194", "65da7ee367b8da003f211e1954e47764",
	"2ec8247c81c4f99aeb1e312f52733aae", "e6c6230de334a3d8ff12cfcc86ef57af", "dd39e1c98fa453030fdda7706162d527", "7618b68e882ea10dcd65b30cf17db167",
	"855e3a8864d77c96b46a4a779a7c0d57", "33e5810c9813dfa81a7ff89747fe339c", "f25fe73af559bbca7a2e17772e51256d", "e72ba67d0c7f4eb2897df59048f94224",
	"bd9b68b9a5a0cb7d60cca43dd1c80f70", "28f8a9974b018e1e02a5e833caef58f8", "c7104df3314eaf4d13c6a8a5d082e347", "28bb26f64eab7c575f79c594e527edf6",
	"966c5858c9889198d98fb4d5b02c3a8b", "88c076a0f558cc132c424b1dd20f2a93", "475688ad0d3867d04abb316b390e02c1", "d0582707735ad047785deb0a5a07f65c",
	"4e2d4ee97a1d4454a43ebd3a95674f3b", "bcee33370c25d4ed23c76711aa65e326", "98a51d642a2dd092942a0c4ab25eaf3d", "56ca762dfef76cae5d2f2da4328591c7",
	"1b6fd9082a7624adf78dfa59ec839072",
}

var testVectors256 = []string{
	"3f863434820cdcc6d9facb44b6cc426a73d8a50ea6f6de1825120dd063f69635", "2424d22b3d8b5100972e61bf191679e59df9fa1770f0daf4d6b509552ce66ae3",
	"26857d06c51c02811a91a687bcc1efbefe5706f805c6aee2272398dfb576653c", "702cdbb5c0728d1174ca38f54be6e20b74aadd41fe337b66e1133e30399519b6",
	"3b87fde4b2b8c94a97fc5fa465e20fde3bda6a896f47c11fe771b330aeb48076", "4f21885e6bbc8a516b02062b5ba062fd95e7db388b8e979c54f06f8801244141",
	"d9a7be3208efed2dfc4479abaee0ef4480e9a174937caa09fb07c507b5b84d71", "aad3d3e35d13a26f5661e390a8a9eec095b07d818cdbc1fa276383969078427b",
	"5cfc1f8b517c25270faba19d668ecc2680a6a061c6177bcdbfb9a30aeca7d031", "6cf21a0a906918b9430bf27f4bd7b09575b531f9f6ab6c2a65196ae6c94d7369",
	"0fd34d5c1fa37ddd697b0a9a240d9408f281eac5d13a7dae212b60c6b51d7096", "8746e64708234a2e38b0488ec37661f9bce126308ab8d09e19fefc46ca5dab9a",
	"4226acfb4bf05c3edf09170081351a59a2103ca65f8f28a008c1a241364db985", "501390d8fa954a4533c82a5de7e84655c1f2b5b4acf25fcf2ed628803114f314",
	"a9341fb81f25ed0da68a6131db1121c45d0cb0702b35c3c1c2f098c3db4789dc", "729e4eab00a191c511d9d8b0a7d2cf4c70f7a31bdefded6fa108e7f6a2c5e503",
	"8a447b5ecc427c5331229b24043e34a76d9bfe7e691db52c979a691a14839d58", "70b84303a66e7e3fd7d496e207e9274e94f7bbaaf15b528728c66e20dcc4036b",
	"3ce056a8d7a41b74fa9a4cb62c429837dd3fd320979cd8b1c3b5e3c47f60de08", "66a45bc84273d7777ed9f6583c601ca0eaa49e30a7f02a34944ba6f6b38e959c",
	"3f76fc1fddaddc9eef36e99b6eaa9bbdf7944a1a8ff7b0aa024cda01a69c1de7", "88f82b420a0daae335104173814c7307f65a54de1950088a79a721120b523cbc",
	"9d43e5c5020c171674c1bf134500c645c85e225dd63acf350ec9372d70aa0be1", "c6ab43ea473bd66bc0241e658abe08cc8a99f86ffcf064b589e53242a309e43e",
	"81bb554357e5ced66da171b240ff318ee9cacceabeedecc3e9923ba2d36c3819", "b1db48d2055e47322ce73028126a39f299b80d8c679583b86670242aa210d48b",
	"43eb75473c3bfa0b00a2b26fc3966549ddd750f13e530fa0c472b5abbc0bd7b5", "b191d63ed30e2b933dc5a3ceed9483b55527136b78e035b9ba743f2b3298093e",
	"a756d1bde12c1fe2b563136ea51845763fb939ecd3511246c44c66c946fec133", "7dcdc984613fbd8ac07f013766819581de654752933e4b280e2d36a9db7b1456",
	"b60728347206051f0d91831a09d10a9b211e3b8ca5d43af28167a1bec06e98cc", "ce106bf9de6431056c8f6de315da5a1def72044c5343fb064809eafdd10e1c02",
	"02e665a6c5a42bf6560c4389fd890d493c7e9b8abe23f41819c6ca4dda5d9e76", "84667af0fa25bdda27b93615d25ca8acd1d3e3b450e005ac81d9cc75247b42be",
	"8c9ff8345ab3a289e6345d87b2510e1a1939125ef43c57ba8a13f1085b81501c", "f7aff260becc9033c2793e6445d2e2d9f5cdd3858fa704118fa5539c8ff3557e",
	"0e6c459d1aae89c10fa404423d4caa06a951d4a90534384b1ec3f0aebc4ca37e", "df4dae19cca75fb42074a69b8e416c3096c0484d0dd816dfcc758dbc509e16d3",
	"890c711370369458f36ae784d5e69ed305e5ddbc14a4555cbf74b11c567da98f", "dd399fd549573587f4502ce711b3b8267be353cecba81119f6959bc35264255c",
	"2128c8abc9879e8b2ddc9cb606fca5121d5e5e80ff0451f92e59d57a25d2d4e5", "48e0e1022b24895a7e0a88d1aa021677437838087650340f240f4feaf345fb7a",
	"00defd500180e33b1ad81af98f907178c115bb51f3070ea01ad110fde7589642", "4c45bad16c1a2b2b8a3022c0a58c9ef174cfc3f7b60efaaec7e758520a33f421",
	"bea910296206c8d1b141f598f54e22fe49d84dec5a435ab98ee657ab77a242d9", "28b3d2e81671bf1613fc31a98ec97db3118c2c599a85e8181617c6c4160f5911",
	"ae247b4c2d1246d0115634d7df9908bdf9dfe60db5ecaa91fa0fa9ba9648dc6e", "6d95ea35817be92f3cf24efb0009a5fb68a37e3f3607c90be2ce4b09d382c9a5",
	"45f2a0a35bfb7b24eb03dbff4addcb6a19b673d3277423a48c722b301d049cfa", "ef806b9d900931f9942730ee6b1a32d1d358c485791e3ed695de6f6c4fd44c64",
	"b065be3f662c52d0f533ea02f366f37891c887cbd166edb91a1c9dba9822eb0c", "e86492569b0ed660ea171474a54744e3c3aff3bd08215204fa255b582dfef490",
	"121bb8aa621641af392fbaa1bb8ed53a7de37958ebe8e073c53f3d618f8f0ece", "c6f1fde1b96c75cabd342d71811d7389c25909832d0b52bfefe94cb22bd15ed3",
	"458003bf5ab6b25fd6142e53f8322d3fc858dd5cc93c4406b88ece8cbe6ffc30", "738d84024f77a9946887b4c0c4aff983265ab2d9fbf57bdb9b63fa6f26507d7f",
	"dd5962645c772a3532985372b432b5b28cb32f0a05ae819900dcf604e84136e1", "5233e7045a000e080c216a19eaf61403a407e39c8680ea2900be04de9aebab4f",
	"df5a3333a5a474565b586cff50067c3c12684446824f4e38816debe0a5ad2dae", "f7a1b0894a79ceb6dd3c47c97eb8c20d889c89a26c009a343cf36bdfb71c414b",
	"afbde66c60b59bd7c1a5187844ea404084524710578cd553ba0826090e73a83d", "5c082ea1daa20059dd93c410c590d4801b8d7c24b017df4b67cecfd6909464a8",
	"470d18107bb0dafb92e243dc6b196ced1d79a27f0794d4e785bf1bd04f8d10c7", "67e46a6e23d66543a508439d9040d5b3688d58d4ab0782e31323c9a84928d4bb",
	"f5265141feb54d0695c5a929fbf88a24f7ffb342a73386507047c300a8dccf24",
}

func benchmarkWrite(size int64, b *testing.B) {
	var key [32]byte
	data := make([]byte, size)

	h, err := New128(key[:])
	if err != nil {
		panic(err)
	}

	b.SetBytes(size)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		h.Write(data)
	}
}

func BenchmarkWrite_8(b *testing.B)  { benchmarkWrite(8, b) }
func BenchmarkWrite_16(b *testing.B) { benchmarkWrite(16, b) }
func BenchmarkWrite_64(b *testing.B) { benchmarkWrite(64, b) }
func BenchmarkWrite_1K(b *testing.B) { benchmarkWrite(1024, b) }
func BenchmarkWrite_8K(b *testing.B) { benchmarkWrite(8*1024, b) }

func benchmarkSum64(size int64, b *testing.B) {
	var key [32]byte
	data := make([]byte, size)

	b.SetBytes(size)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		Sum64(data, key[:])
	}
}

func BenchmarkSum64_8(b *testing.B)  { benchmarkSum64(8, b) }
func BenchmarkSum64_16(b *testing.B) { benchmarkSum64(16, b) }
func BenchmarkSum64_64(b *testing.B) { benchmarkSum64(64, b) }
func BenchmarkSum64_1K(b *testing.B) { benchmarkSum64(1024, b) }
func BenchmarkSum64_8K(b *testing.B) { benchmarkSum64(8*1024, b) }

func benchmarkSum256(size int64, b *testing.B) {
	var key [32]byte
	data := make([]byte, size)

	b.SetBytes(size)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		Sum(data, key[:])
	}
}

func BenchmarkSum256_8(b *testing.B)  { benchmarkSum256(8, b) }
func BenchmarkSum256_16(b *testing.B) { benchmarkSum256(16, b) }
func BenchmarkSum256_64(b *testing.B) { benchmarkSum256(64, b) }
func BenchmarkSum256_1K(b *testing.B) { benchmarkSum256(1024, b) }
func BenchmarkSum256_8K(b *testing.B) { benchmarkSum256(8*1024, b) }
