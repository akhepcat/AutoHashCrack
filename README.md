# AutoHashCrack
Automated hashcat cracking of hash-separated files

Given filenames like this:
*       vendor1-half_md5-m200.hash
*       server1-md5crypt-m500.hash
*       server2-descrypt-m1500.hash
*       vendor2-sha3_256-m5000.hash
*       vendor3-m900.hash

we can programmatically run hashcat correctly.

Additionally, it's possible to parse optional paramaters, such as 
*       -a|--attack-mode
*       -r|--rules-file
*       --potfile-path
*       [maskfile]
*       [single-rule]|-A (automatic rules)


AutoHashCrack will save and restore sessions automatically.
