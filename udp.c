#define _GNU_SOURCE
/**************************************************************************
 * simpletun.c                                                            *
 *                                                                        *
 * A simplistic, simple-minded, naive tunnelling program using tun/tap    *
 * interfaces and TCP. Handles (badly) IPv4 for tun, ARP and IPv4 for     *
 * tap. DO NOT USE THIS PROGRAM FOR SERIOUS PURPOSES.                     *
 *                                                                        *
 * You have been warned.                                                  *
 *                                                                        *
 * (C) 2009 Davide Brini.                                                 *
 *                                                                        *
 * DISCLAIMER AND WARNING: this is all work in progress. The code is      *
 * ugly, the algorithms are naive, error checking and input validation    *
 * are very basic, and of course there can be bugs. If that's not enough, *
 * the program has not been thoroughly tested, so it might even fail at   *
 * the few simple things it should be supposed to do right.               *
 * Needless to say, I take no responsibility whatsoever for what the      *
 * program might do. The program has been written mostly for learning     *
 * purposes, and can be used in the hope that is useful, but everything   *
 * is to be taken "as is" and without any kind of warranty, implicit or   *
 * explicit. See the file LICENSE for further details.                    *
 *************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/if.h>
#include <linux/if_tun.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/time.h>
#include <errno.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <openssl/rand.h>
#include <openssl/ssl.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <sys/mman.h>
#include <sys/shm.h>
#include <inttypes.h>
#include <stdbool.h>
#include <signal.h>

/* buffer for reading from tun/tap interface, must be >= 1500 */
#define BUFSIZE 2000
#define CLIENT 0
#define SERVER 1
#define PORT 55555
#define FAIL -1
#define LOG_DATA 1
#define PRINT_DATA 0
#define PRINT_HASHMAP 0
#define atoa(x) #x

/* some common lengths */
#define IP_HDR_LEN 20
#define ETH_HDR_LEN 14
#define ARP_PKT_LEN 28
#define IS_IV_SECRET 0

int debug;
char *progname;

unsigned char session_key[32];
unsigned char session_iv[16];
unsigned char peer_spi[4];

struct vpn_client
{
    uint32_t peer_ip;
    uint32_t vpn_ip;
    uint16_t peer_port;
    uint32_t num_pkt;
    unsigned char conn_spi[4];
    unsigned char session_key[32];
    unsigned char session_iv[16];
    uint8_t key_update;
    uint8_t iv_update;
    uint8_t all_update;
    uint8_t conn_break;
    uint8_t del_all;
};

struct key_ids
{
    uint64_t c1;
    uint64_t c2;
    uint64_t c3;
    uint64_t c4;
    uint64_t c5;
    uint64_t c6;
    uint64_t c7;
    uint64_t c8;
};

struct iv_ids
{
    uint64_t c1;
    uint64_t c2;
    uint64_t c3;
    uint64_t c4;
};

#define SIZE1 3
#define SIZE2 3

struct DataItem
{
    uint32_t peer_ip;
    uint32_t vpn_ip;
    uint16_t peer_port;
    uint32_t num_pkt;
    uint64_t spi_int;
    uint64_t ck1;
    uint64_t ck2;
    uint64_t ck3;
    uint64_t ck4;
    uint64_t ck5;
    uint64_t ck6;
    uint64_t ck7;
    uint64_t ck8;
    uint64_t cv1;
    uint64_t cv2;
    uint64_t cv3;
    uint64_t cv4;
};

struct sctpheader
{
    unsigned short int sctp_srcport;
    unsigned short int sctp_dstport;
    unsigned long int sctp_vtag;
    unsigned long int sctp_chksum;
};

struct DataItem *hashArray[SIZE1];
struct DataItem *hashArray2[SIZE2];
struct DataItem *vpn_peer_local;
struct DataItem *vpn_peer_local2;
struct DataItem *dummyItem;
struct DataItem *dummyItem2;

int hashCodePeer(int key_peer)
{
    return key_peer % SIZE1;
}

int hashCodeVpn(int key_vpn)
{
    return key_vpn % SIZE2;
}

struct DataItem *search_peer(int key, int ip_type)
{
    // get the hash
    if (ip_type == 1)
    {
        int hashIndex = hashCodePeer(key);

        // move in array until an empty
        while (hashArray[hashIndex] != NULL)
        {

            if (hashArray[hashIndex]->peer_ip == key)
                return hashArray[hashIndex];

            // go to next cell
            ++hashIndex;

            // wrap around the table
            hashIndex %= SIZE1;
        }
    }
    else
    {
        int hashIndex2 = hashCodeVpn(key);

        // move in array until an empty
        while (hashArray2[hashIndex2] != NULL)
        {

            if (hashArray2[hashIndex2]->vpn_ip == key)
                return hashArray2[hashIndex2];

            // go to next cell
            ++hashIndex2;

            // wrap around the table
            hashIndex2 %= SIZE2;
        }
    }

    return NULL;
}

void insert(uint32_t peer_ip, uint32_t vpn_ip, uint16_t peer_port, uint32_t num_pkt, uint64_t spi_int, uint64_t ck1, uint64_t ck2, uint64_t ck3, uint64_t ck4, uint64_t ck5, uint64_t ck6, uint64_t ck7, uint64_t ck8, uint64_t cv1, uint64_t cv2, uint64_t cv3, uint64_t cv4, int ip_typye)
{

    if (ip_typye == 1)
    {
        struct DataItem *vpn_peer_local = (struct DataItem *)malloc(sizeof(struct DataItem));
        vpn_peer_local->peer_ip = peer_ip;
        vpn_peer_local->vpn_ip = vpn_ip;
        vpn_peer_local->peer_port = peer_port;
        vpn_peer_local->num_pkt = num_pkt;
        vpn_peer_local->spi_int = spi_int;
        vpn_peer_local->ck1 = ck1;
        vpn_peer_local->ck2 = ck2;
        vpn_peer_local->ck3 = ck3;
        vpn_peer_local->ck4 = ck4;
        vpn_peer_local->ck5 = ck5;
        vpn_peer_local->ck6 = ck6;
        vpn_peer_local->ck7 = ck7;
        vpn_peer_local->ck8 = ck8;
        vpn_peer_local->cv1 = cv1;
        vpn_peer_local->cv2 = cv2;
        vpn_peer_local->cv3 = cv3;
        vpn_peer_local->cv4 = cv4;
        int hashIndex;

        // get the hash
        hashIndex = hashCodePeer(peer_ip);

        // move in array until an empty or deleted cell
        while (hashArray[hashIndex] != NULL && hashArray[hashIndex]->peer_ip != -1)
        {
            // go to next cell
            ++hashIndex;

            // wrap around the table
            hashIndex %= SIZE1;
        }
        hashArray[hashIndex] = vpn_peer_local;
    }
    else
    {
        struct DataItem *vpn_peer_local2 = (struct DataItem *)malloc(sizeof(struct DataItem));
        vpn_peer_local2->peer_ip = peer_ip;
        vpn_peer_local2->vpn_ip = vpn_ip;
        vpn_peer_local2->peer_port = peer_port;
        vpn_peer_local2->num_pkt = num_pkt;
        vpn_peer_local2->spi_int = spi_int;
        vpn_peer_local2->ck1 = ck1;
        vpn_peer_local2->ck2 = ck2;
        vpn_peer_local2->ck3 = ck3;
        vpn_peer_local2->ck4 = ck4;
        vpn_peer_local2->ck5 = ck5;
        vpn_peer_local2->ck6 = ck6;
        vpn_peer_local2->ck7 = ck7;
        vpn_peer_local2->ck8 = ck8;
        vpn_peer_local2->cv1 = cv1;
        vpn_peer_local2->cv2 = cv2;
        vpn_peer_local2->cv3 = cv3;
        vpn_peer_local2->cv4 = cv4;
        int hashIndex2;

        hashIndex2 = hashCodeVpn(vpn_ip);

        // move in array until an empty or deleted cell
        while (hashArray2[hashIndex2] != NULL && hashArray2[hashIndex2]->vpn_ip != -1)
        {
            // go to next cell
            ++hashIndex2;

            // wrap around the table
            hashIndex2 %= SIZE2;
        }
        hashArray2[hashIndex2] = vpn_peer_local2;
    }
}

struct DataItem *delete_peer(struct DataItem *item, int ip_type)
{
    if (ip_type == 1)
    {
        int peer_ip = item->peer_ip;

        // get the hash
        int hashIndex = hashCodePeer(peer_ip);

        // move in array until an empty
        while (hashArray[hashIndex] != NULL)
        {

            if (hashArray[hashIndex]->peer_ip == peer_ip)
            {
                struct DataItem *temp = hashArray[hashIndex];

                // assign a dummy item at deleted position
                hashArray[hashIndex] = dummyItem;
                return temp;
            }

            // go to next cell
            ++hashIndex;

            // wrap around the table
            hashIndex %= SIZE1;
        }
    }
    else
    {
        int vpn_ip = item->vpn_ip;

        // get the hash
        int hashIndex2 = hashCodeVpn(vpn_ip);

        // move in array until an empty
        while (hashArray2[hashIndex2] != NULL)
        {

            if (hashArray2[hashIndex2]->vpn_ip == vpn_ip)
            {
                struct DataItem *temp2 = hashArray2[hashIndex2];

                // assign a dummy item at deleted position
                hashArray2[hashIndex2] = dummyItem2;
                return temp2;
            }

            // go to next cell
            ++hashIndex2;

            // wrap around the table
            hashIndex2 %= SIZE2;
        }
    }

    return NULL;
}

void display(int ip_typye)
{
    int i = 0;

    if (ip_typye == 1)
    {

        for (i = 0; i < SIZE1; i++)
        {

            if (hashArray[i] != NULL)
                printf("HashMap is peer_ip,  vpn_ip,  peer_port,  num_pkt,  spi_int,  ck1,  ck2,  ck3,  ck4,  ck5,  ck6,  ck7,  ck8,  cv1,  cv2,  cv3,  cv4 (%d,%d,%d,%d,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu)\n", hashArray[i]->peer_ip, hashArray[i]->vpn_ip, hashArray[i]->peer_port, hashArray[i]->num_pkt, hashArray[i]->spi_int, hashArray[i]->ck1, hashArray[i]->ck2, hashArray[i]->ck3, hashArray[i]->ck4, hashArray[i]->ck5, hashArray[i]->ck6, hashArray[i]->ck7, hashArray[i]->ck8, hashArray[i]->cv1, hashArray[i]->cv2, hashArray[i]->cv3, hashArray[i]->cv4);
            else
                printf(" ~~ ");
        }
    }
    else
    {
        for (i = 0; i < SIZE2; i++)
        {

            if (hashArray2[i] != NULL)
                printf("HashMap2 is peer_ip,  vpn_ip,  peer_port,  num_pkt,  spi_int,  ck1,  ck2,  ck3,  ck4,  ck5,  ck6,  ck7,  ck8,  cv1,  cv2,  cv3,  cv4 (%d,%d,%d,%d,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu)\n", hashArray2[i]->peer_ip, hashArray2[i]->vpn_ip, hashArray2[i]->peer_port, hashArray2[i]->num_pkt, hashArray2[i]->spi_int, hashArray2[i]->ck1, hashArray2[i]->ck2, hashArray2[i]->ck3, hashArray2[i]->ck4, hashArray2[i]->ck5, hashArray2[i]->ck6, hashArray2[i]->ck7, hashArray2[i]->ck8, hashArray2[i]->cv1, hashArray2[i]->cv2, hashArray2[i]->cv3, hashArray2[i]->cv4);
            else
                printf(" ~~ ");
        }
    }

    printf("\n");
}

uint64_t xtou64(const char *str)
{
    uint64_t res = 0;
    char c;

    while ((c = *str++))
    {
        char v = (c & 0xF) + (c >> 6) | ((c >> 3) & 0x8);
        res = (res << 4) | (uint64_t)v;
    }

    return res;
}

struct key_ids key_to_int(unsigned char val[32])
{
    struct key_ids key_ints;
    char *uk1;
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[0], val[1], val[2], val[3]);
    key_ints.c1 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[4], val[5], val[6], val[7]);
    key_ints.c2 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[8], val[9], val[10], val[11]);
    key_ints.c3 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[12], val[13], val[14], val[15]);
    key_ints.c4 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[16], val[17], val[18], val[19]);
    key_ints.c5 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[20], val[21], val[22], val[23]);
    key_ints.c6 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[24], val[25], val[26], val[27]);
    key_ints.c7 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[28], val[29], val[30], val[31]);
    key_ints.c8 = xtou64(uk1);
    // printf("KEY Ints are %llu %llu %llu %llu %llu %llu %llu %llu\n", key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8);
    return key_ints;
}

struct iv_ids iv_to_int(unsigned char val[32])
{
    struct iv_ids iv_ints;
    char *uk1;
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[0], val[1], val[2], val[3]);
    iv_ints.c1 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[4], val[5], val[6], val[7]);
    iv_ints.c2 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[8], val[9], val[10], val[11]);
    iv_ints.c3 = xtou64(uk1);
    asprintf(&uk1, "%.02x%.02x%.02x%.02x", val[12], val[13], val[14], val[15]);
    iv_ints.c4 = xtou64(uk1);
    // printf("IV Ints are %llu %llu %llu %llu\n", iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4);
    return iv_ints;
}

int print_hashmap(uint32_t peer_ip, uint32_t vpn_ip, uint16_t peer_port, uint32_t num_pkt, uint64_t spi_int, struct key_ids key_ints, struct iv_ids iv_ints)
{
    printf("\n");
    printf("----- Session Info -----\n");
    int i;
    char *spi_hex;
    asprintf(&spi_hex, "%08lx", spi_int);
    char spistring[8];
    // strcpy(spistring, spi_hex);
    memcpy(spistring, spi_hex, 8);
    const char *spi_pos = spistring;
    unsigned char spi_val[4];
    size_t count;
    for (count = 0; count < sizeof spi_val / sizeof *spi_val; count++)
    {
        sscanf(spi_pos, "%2hhx", &spi_val[count]);
        spi_pos += 2;
    }

    char *all_hex;
    asprintf(&all_hex, "%08lx%08lx%08lx%08lx%08lx%08lx%08lx%08lx", key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8);
    char keystring[64];
    // strcpy(keystring, all_hex);
    memcpy(keystring, all_hex, 64);
    const char *key_pos = keystring;
    unsigned char key_val[32];
    for (count = 0; count < sizeof key_val / sizeof *key_val; count++)
    {
        sscanf(key_pos, "%2hhx", &key_val[count]);
        key_pos += 2;
    }

    char *iv_hex;
    asprintf(&iv_hex, "%08lx%08lx%08lx%08lx", iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4);
    char ivstring[32];
    // strcpy(ivstring, iv_hex);
    memcpy(ivstring, iv_hex, 32);
    const char *iv_pos = ivstring;
    unsigned char iv_val[16];
    for (count = 0; count < sizeof iv_val / sizeof *iv_val; count++)
    {
        sscanf(iv_pos, "%2hhx", &iv_val[count]);
        iv_pos += 2;
    }

    printf("SPI: ");
    for (i = 0; i < 4; i++)
        printf("%.02x", spi_val[i]);
    printf("\n");

    struct in_addr ip_addr2;
    ip_addr2.s_addr = vpn_ip;
    printf("VPN IP is: %s\n", inet_ntoa(ip_addr2));

    struct in_addr ip_addr;
    ip_addr.s_addr = peer_ip;
    printf("Peer IP and Port: %s & %d\n", inet_ntoa(ip_addr), peer_port);

    printf("IV: ");
    for (i = 0; i < 16; i++)
        printf("%.02x", iv_val[i]);
    printf("\n");

    printf("Session KEY: ");
    for (i = 0; i < 32; i++)
        printf("%.02x", key_val[i]);
    printf("\n");

    printf("--------------------------\n");
    printf("\n");

    return 0;
}

/**************************************************************************
 * tun_alloc: allocates or reconnects to a tun/tap device. The caller     *
 *            needs to reserve enough space in *dev.                      *
 **************************************************************************/
int tun_alloc(char *dev, int flags)
{

    struct ifreq ifr;
    int fd, err;

    if ((fd = open("/dev/net/tun", O_RDWR)) < 0)
    {
        perror("Opening /dev/net/tun");
        return fd;
    }

    memset(&ifr, 0, sizeof(ifr));

    ifr.ifr_flags = flags;

    if (*dev)
    {
        strncpy(ifr.ifr_name, dev, IFNAMSIZ);
    }

    if ((err = ioctl(fd, TUNSETIFF, (void *)&ifr)) < 0)
    {
        perror("ioctl(TUNSETIFF)");
        close(fd);
        return err;
    }

    strcpy(dev, ifr.ifr_name);

    return fd;
}

/**************************************************************************
 * cread: read routine that checks for errors and exits if an error is    *
 *        returned.                                                       *
 **************************************************************************/
int cread(int fd, char *buf, int n)
{

    int nread;

    if ((nread = read(fd, buf, n)) < 0)
    {
        perror("Reading data");
        exit(1);
    }
    return nread;
}

/**************************************************************************
 * cwrite: write routine that checks for errors and exits if an error is  *
 *         returned.                                                      *
 **************************************************************************/
int cwrite(int fd, char *buf, int n)
{

    int nwrite;

    if ((nwrite = write(fd, buf, n)) < 0)
    {
        perror("Writing data");
        //exit(1);
        nwrite = 0;
    }
    return nwrite;
}

/**************************************************************************
 * read_n: ensures we read exactly n bytes, and puts those into "buf".    *
 *         (unless EOF, of course)                                        *
 **************************************************************************/
int read_n(int fd, char *buf, int n)
{

    int nread, left = n;

    while (left > 0)
    {
        if ((nread = cread(fd, buf, left)) == 0)
        {
            return 0;
        }
        else
        {
            left -= nread;
            buf += nread;
        }
    }
    return n;
}

/**************************************************************************
 * do_debug: prints debugging stuff (doh!)                                *
 **************************************************************************/
void do_debug(char *msg, ...)
{

    va_list argp;

    if (debug)
    {
        va_start(argp, msg);
        vfprintf(stderr, msg, argp);
        va_end(argp);
    }
}

/**************************************************************************
 * my_err: prints custom error messages on stderr.                        *
 **************************************************************************/
void my_err(char *msg, ...)
{

    va_list argp;

    va_start(argp, msg);
    vfprintf(stderr, msg, argp);
    va_end(argp);
}

/**************************************************************************
 * usage: prints usage and exits.                                         *
 **************************************************************************/
void usage(void)
{
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "%s -i <ifacename> [-s|-c <serverIP>] [-p <port>] [-u|-a] [-d]\n", progname);
    fprintf(stderr, "%s -h\n", progname);
    fprintf(stderr, "\n");
    fprintf(stderr, "-i <ifacename>: Name of interface to use (mandatory)\n");
    fprintf(stderr, "-s|-c <serverIP>: run in server mode (-s), or specify server address (-c <serverIP>) (mandatory)\n");
    fprintf(stderr, "-p <port>: port to listen on (if run in server mode) or to connect to (in client mode), default 55555\n");
    fprintf(stderr, "-u|-a: use TUN (-u, default) or TAP (-a)\n");
    fprintf(stderr, "-d: outputs debug information while running\n");
    fprintf(stderr, "-h: prints this help text\n");
    exit(1);
}

void handleErrors(void)
{
    ERR_print_errors_fp(stderr);
    abort();
}

SSL_CTX *create_context(const SSL_METHOD *method)
{
    SSL_library_init();
    SSL_CTX *ctx;
    OpenSSL_add_all_algorithms(); /* Load cryptos, et.al. */
    SSL_load_error_strings();     /* Bring in and register error messages */
    // method = TLSv1_2_client_method(); /* Create new client-method instance */
    ctx = SSL_CTX_new(method); /* Create new context */
    if (ctx == NULL)
    {
        handleErrors();
    }
    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL); /* whether verify the certificate */
    // SSL_CTX_set_verify_depth(ctx, 4);
    /* Cannot fail ??? */
    const long flags = SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION;
    SSL_CTX_set_options(ctx, flags);
    return ctx;
}

void show_certs(SSL *ssl)
{
    X509 *cert;
    char *line;
    cert = SSL_get_peer_certificate(ssl); /* get the server's certificate */
    if (cert != NULL)
    {
        printf("\nPeer Certificates:\n");
        line = X509_NAME_oneline(X509_get_subject_name(cert), 0, 0);
        printf("Subject: %s\n", line);
        free(line); /* free the malloc'ed string */
        line = X509_NAME_oneline(X509_get_issuer_name(cert), 0, 0);
        printf("Issuer: %s\n", line);
        free(line);      /* free the malloc'ed string */
        X509_free(cert); /* free the malloc'ed certificate copy */
    }
    else
    {
        printf("Info: No peer certificates configured.\n");
        // handleErrors();
    }
    long res = SSL_get_verify_result(ssl);
    if (!(X509_V_OK == res))
    {
        handleErrors();
    }
}

void configure_verify_context(SSL_CTX *ctx, char *ca_cert, char *cert_file, char *key_file)
{
    long res = SSL_CTX_load_verify_locations(ctx, ca_cert, NULL);
    if (!(1 == res))
        handleErrors();

    /* Set the key and cert */
    if (SSL_CTX_use_certificate_file(ctx, cert_file, SSL_FILETYPE_PEM) <= 0)
    {
        handleErrors();
    }

    if (SSL_CTX_use_PrivateKey_file(ctx, key_file, SSL_FILETYPE_PEM) <= 0)
    {
        handleErrors();
    }

    /* verify private key */
    if (!SSL_CTX_check_private_key(ctx))
    {
        fprintf(stderr, "Private key does not match the public certificate\n");
        abort();
    }
}

int hmac_it(const unsigned char *msg, size_t mlen, unsigned char **val, size_t *vlen, EVP_PKEY *pkey)
{
    /* Returned to caller */
    int result = 0;
    EVP_MD_CTX *ctx = NULL;
    size_t req = 0;
    int rc;

    if (!msg || !mlen || !val || !pkey)
        return 0;

    *val = NULL;
    *vlen = 0;

    ctx = EVP_MD_CTX_create();
    if (ctx == NULL)
    {
        printf("EVP_MD_CTX_create failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    rc = EVP_DigestSignInit(ctx, NULL, EVP_sha256(), NULL, pkey);
    if (rc != 1)
    {
        printf("EVP_DigestSignInit failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    rc = EVP_DigestSignUpdate(ctx, msg, mlen);
    if (rc != 1)
    {
        printf("EVP_DigestSignUpdate failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    rc = EVP_DigestSignFinal(ctx, NULL, &req);
    if (rc != 1)
    {
        printf("EVP_DigestSignFinal failed (1), error 0x%lx\n", ERR_get_error());
        goto err;
    }

    *val = OPENSSL_malloc(req);
    if (*val == NULL)
    {
        printf("OPENSSL_malloc failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    *vlen = req;
    rc = EVP_DigestSignFinal(ctx, *val, vlen);
    if (rc != 1)
    {
        printf("EVP_DigestSignFinal failed (3), return code %d, error 0x%lx\n", rc, ERR_get_error());
        goto err;
    }

    result = 1;

err:
    EVP_MD_CTX_destroy(ctx);
    if (!result)
    {
        OPENSSL_free(*val);
        *val = NULL;
    }
    return result;
}

int verify_it(const unsigned char *msg, size_t mlen, const unsigned char *val, size_t vlen, EVP_PKEY *pkey)
{
    /* Returned to caller */
    int result = 0;
    EVP_MD_CTX *ctx = NULL;
    unsigned char buff[EVP_MAX_MD_SIZE];
    size_t size;
    int rc;

    if (!msg || !mlen || !val || !vlen || !pkey)
        return 0;

    ctx = EVP_MD_CTX_create();
    if (ctx == NULL)
    {
        printf("EVP_MD_CTX_create failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    rc = EVP_DigestSignInit(ctx, NULL, EVP_sha256(), NULL, pkey);
    if (rc != 1)
    {
        printf("EVP_DigestSignInit failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    rc = EVP_DigestSignUpdate(ctx, msg, mlen);
    if (rc != 1)
    {
        printf("EVP_DigestSignUpdate failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    size = sizeof(buff);
    rc = EVP_DigestSignFinal(ctx, buff, &size);
    if (rc != 1)
    {
        printf("EVP_DigestSignFinal failed, error 0x%lx\n", ERR_get_error());
        goto err;
    }

    result = (vlen == size) && (CRYPTO_memcmp(val, buff, size) == 0);
err:
    EVP_MD_CTX_destroy(ctx);
    return result;
}

int aes_encrypt(unsigned char *plaintext, int plaintext_len, unsigned char *key,
                unsigned char *iv, unsigned char *ciphertext)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int ciphertext_len;

    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new()))
        handleErrors();

    /*
     * Initialise the encryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits
     */
    if (1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
        handleErrors();

    /*
     * Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if (1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
        handleErrors();
    ciphertext_len = len;

    /*
     * Finalise the encryption. Further ciphertext bytes may be written at
     * this stage.
     */
    if (1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
        handleErrors();
    ciphertext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

int decrypt(unsigned char *ciphertext, int ciphertext_len, unsigned char *key,
            unsigned char *iv, unsigned char *plaintext)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int plaintext_len;

    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new()))
        handleErrors();

    /*
     * Initialise the decryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits
     */
    if (1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv))
        handleErrors();

    /*
     * Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary.
     */
    if (1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        handleErrors();
    plaintext_len = len;

    /*
     * Finalise the decryption. Further plaintext bytes may be written at
     * this stage.
     */
    if (1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len))
        handleErrors();
    plaintext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return plaintext_len;
}

void send_recv_udp(int tap_fd, struct vpn_client *vpn_peer, uint16_t my_udp_port)
{
    int maxfd, net_fd, num_pkt = 0;
    uint16_t nread, nwrite;
    unsigned char buffer[BUFSIZE];
    unsigned char cipher_text[BUFSIZE];
    unsigned char plain_text[BUFSIZE];
    unsigned char tx_buf[BUFSIZE];
    unsigned char data_buf[BUFSIZE];
    unsigned char hash_buf[32];
    struct sockaddr_in local, remote;
    socklen_t remotelen;
    unsigned long int tap2net = 0, net2tap = 0;

    unsigned char sess_spi[4];
    unsigned char sess_key[32];
    unsigned char sess_iv[16];

    struct sockaddr_in rx_buf;
    struct sockaddr *rx = (struct sockaddr *)&rx_buf;
    socklen_t rx_len = sizeof(rx_buf);

    const size_t sig_len = 32;
    unsigned char *val = NULL;
    size_t vlen = 0;

    if ((net_fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("socket()");
        exit(1);
    }
    memset(&local, 0, sizeof(local));
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = htonl(INADDR_ANY);
    local.sin_port = htons(my_udp_port);

    if (bind(net_fd, (struct sockaddr *)&local, sizeof(local)) < 0)
    {
        perror("bind()");
        exit(1);
    }
    // memcpy(&remote, &remote_sock, sizeof(remote));
    // remote.sin_port = htons(UDPPORT);
    remotelen = sizeof(remote);
    memset(&remote, 0, remotelen);

    /* use select() to handle two descriptors at once */
    maxfd = (tap_fd > net_fd) ? tap_fd : net_fd;

    // sleep(30);
    while (1)
    {
        int i;
        int ret;
        fd_set rd_set;

        FD_ZERO(&rd_set);
        FD_SET(tap_fd, &rd_set);
        FD_SET(net_fd, &rd_set);

        ret = select(maxfd + 1, &rd_set, NULL, NULL, NULL);

        if (ret < 0 && errno == EINTR)
        {
            continue;
        }

        if (ret < 0)
        {
            perror("select()");
            exit(1);
        }

        // int i;
        if (FD_ISSET(tap_fd, &rd_set))
        {
            /* data from tun/tap: just read it and write it to the network */

            nread = cread(tap_fd, buffer, sizeof(buffer));

            char dest_ip_arr[4];
            memcpy(dest_ip_arr, buffer + 16, 4);
            char *ck1;
            asprintf(&ck1, "%.02x%.02x%.02x%.02x", dest_ip_arr[0], dest_ip_arr[1], dest_ip_arr[2], dest_ip_arr[3]);
            char *dest_ip;
            unsigned int uint0, uint1, uint2, uint3;
            sscanf(ck1, "%2x%2x%2x%2x", &uint0, &uint1, &uint2, &uint3);
            asprintf(&dest_ip, "%u.%u.%u.%u", uint0, uint1, uint2, uint3);
            struct sctpheader *sctp = (struct sctpheader *)(buffer + 20);
            if (htons(sctp->sctp_srcport) != 38412 && htons(sctp->sctp_dstport) != 38412)
            {
                //continue;
            }
            // printf("Source Port = %d\n", htons(sctp->sctp_srcport));
            // printf("Destination Port = %d\n", htons(sctp->sctp_dstport));

            // printf("\n-- update peers key and IV --\n");
            if (vpn_peer->conn_break)
            {
                vpn_peer_local = search_peer(vpn_peer->peer_ip, 1);
                vpn_peer_local2 = search_peer(vpn_peer->vpn_ip, 2);
                delete_peer(vpn_peer_local, 1);
                delete_peer(vpn_peer_local2, 2);
                vpn_peer->conn_break = 0;
                printf("Deleted entries from HashMap for vpn %s\n", dest_ip);
                continue;
            }
            else if (vpn_peer->del_all)
            {
                memset(hashArray, 0, SIZE1);
                memset(hashArray2, 0, SIZE2);
                vpn_peer->del_all = 0;
            }
            else if (vpn_peer->all_update || vpn_peer->key_update || vpn_peer->iv_update)
            {
                struct key_ids key_ints;
                struct iv_ids iv_ints;
                uint64_t spi_int;

                if (vpn_peer->all_update || vpn_peer->key_update)
                {
                    key_ints = key_to_int(vpn_peer->session_key);
                }
                if (vpn_peer->all_update || vpn_peer->iv_update)
                {
                    iv_ints = iv_to_int(vpn_peer->session_iv);
                }
                if (!vpn_peer->all_update)
                {
                    vpn_peer_local = search_peer(vpn_peer->peer_ip, 1);
                    vpn_peer_local2 = search_peer(vpn_peer->vpn_ip, 2);
                    if (vpn_peer->key_update)
                    {
                        iv_ints.c1 = vpn_peer_local2->cv1;
                        iv_ints.c2 = vpn_peer_local2->cv2;
                        iv_ints.c3 = vpn_peer_local2->cv3;
                        iv_ints.c4 = vpn_peer_local2->cv4;
                    }
                    else if (vpn_peer->iv_update)
                    {
                        key_ints.c1 = vpn_peer_local2->ck1;
                        key_ints.c2 = vpn_peer_local2->ck2;
                        key_ints.c3 = vpn_peer_local2->ck3;
                        key_ints.c4 = vpn_peer_local2->ck4;
                        key_ints.c5 = vpn_peer_local2->ck5;
                        key_ints.c6 = vpn_peer_local2->ck6;
                        key_ints.c7 = vpn_peer_local2->ck7;
                        key_ints.c8 = vpn_peer_local2->ck8;
                    }
                    spi_int = vpn_peer_local->spi_int;
                    delete_peer(vpn_peer_local, 1);
                    delete_peer(vpn_peer_local2, 2);
                }
                else if (vpn_peer->all_update)
                {
                    char *spi_temp;
                    asprintf(&spi_temp, "%.02x%.02x%.02x%.02x", vpn_peer->conn_spi[0], vpn_peer->conn_spi[1], vpn_peer->conn_spi[2], vpn_peer->conn_spi[3]);
                    spi_int = xtou64(spi_temp);
                }

                insert(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8, iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4, 1);
                insert(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8, iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4, 2);

                if (PRINT_DATA)
                {
                    print_hashmap(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints, iv_ints);
                }

                if (PRINT_HASHMAP)
                {
                    // printf("NET2TAP HashMap: ");
                    // display(1);
                    printf("TAP2NET HashMap: ");
                    display(2);
                }

                vpn_peer->key_update = 0;
                vpn_peer->iv_update = 0;
                vpn_peer->all_update = 0;
                vpn_peer->del_all = 0;
            }
            // printf("\n-- get peers %d key and IV for encryption --\n", (uint32_t)inet_addr(dest_ip));
            vpn_peer_local2 = search_peer((uint32_t)inet_addr(dest_ip), 2);
            if (vpn_peer_local2 == NULL)
            {
                printf("Packet entry does not exist in the HashMap for %s; dropping the packet\n", dest_ip);
                continue;
            }

            struct in_addr ip_addr;
            ip_addr.s_addr = vpn_peer_local2->peer_ip;
            remote.sin_addr.s_addr = inet_addr(inet_ntoa(ip_addr));
            uint16_t peer_udp_port = vpn_peer_local2->peer_port;
            remote.sin_port = htons(peer_udp_port);
            num_pkt = vpn_peer_local2->num_pkt;

            char *spi_hex;
            uint64_t spi_int = vpn_peer_local2->spi_int;
            asprintf(&spi_hex, "%08lx", spi_int);
            char spistring[8];
            // strcpy(spistring, spi_hex);
            memcpy(spistring, spi_hex, 8);
            const char *spi_pos = spistring;
            unsigned char spi_val[4];
            size_t count;
            for (count = 0; count < sizeof spi_val / sizeof *spi_val; count++)
            {
                sscanf(spi_pos, "%2hhx", &spi_val[count]);
                spi_pos += 2;
            }
            memcpy(sess_spi, spi_val, 4);

            char *all_hex;
            asprintf(&all_hex, "%08lx%08lx%08lx%08lx%08lx%08lx%08lx%08lx", vpn_peer_local2->ck1, vpn_peer_local2->ck2, vpn_peer_local2->ck3, vpn_peer_local2->ck4, vpn_peer_local2->ck5, vpn_peer_local2->ck6, vpn_peer_local2->ck7, vpn_peer_local2->ck8);
            char keystring[64];
            // strcpy(keystring, all_hex);
            memcpy(keystring, all_hex, 64);
            const char *key_pos = keystring;
            unsigned char key_val[32];
            for (count = 0; count < sizeof key_val / sizeof *key_val; count++)
            {
                sscanf(key_pos, "%2hhx", &key_val[count]);
                key_pos += 2;
            }
            memcpy(sess_key, key_val, 32);

            char *iv_hex;
            asprintf(&iv_hex, "%08lx%08lx%08lx%08lx", vpn_peer_local2->cv1, vpn_peer_local2->cv2, vpn_peer_local2->cv3, vpn_peer_local2->cv4);
            char ivstring[32];
            // strcpy(ivstring, iv_hex);
            memcpy(ivstring, iv_hex, 32);
            const char *iv_pos = ivstring;
            unsigned char iv_val[16];
            for (count = 0; count < sizeof iv_val / sizeof *iv_val; count++)
            {
                sscanf(iv_pos, "%2hhx", &iv_val[count]);
                iv_pos += 2;
            }
            memcpy(sess_iv, iv_val, 16);

            if (PRINT_DATA)
            {
                printf("\nenc sess_spi from map:");
                for (i = 0; i < 4; i++)
                    printf("%.02x", sess_spi[i]);
                printf("\n");

                printf("\nenc sess_key from map:");
                for (i = 0; i < 32; i++)
                    printf("%.02x", sess_key[i]);
                printf("\n");

                printf("\nenc sess_iv from map:");
                for (i = 0; i < 16; i++)
                    printf("%.02x", sess_iv[i]);
                printf("\n");
            }

            tap2net++;
            do_debug("\nTAP2NET %lu: Read %d bytes from the tap interface\n", tap2net, nread);

            if (PRINT_DATA)
            {
                printf("TAP2NET %lu: Plaintext data:", tap2net);
                for (i = 0; i < nread; i++)
                    printf("%.02x", buffer[i]);
                printf("\n");
            }

            if (num_pkt == 0)
            {
                memcpy(tx_buf, sess_iv, 16);
                nwrite = aes_encrypt(buffer, nread, sess_key, sess_iv, cipher_text);
                if (PRINT_DATA)
                {
                    printf("\ncipher_text:");
                    for (i = 0; i < nwrite; i++)
                        printf("%.02x", cipher_text[i]);
                    printf("\n");
                }

                //memcpy(sess_iv, cipher_text + nwrite - 16, 16);
                num_pkt++;
                if (PRINT_DATA)
                {
                    printf("\nNew sess_iv:");
                    for (i = 0; i < 16; i++)
                        printf("%.02x", sess_iv[i]);
                    printf("\n");
                }

                memcpy(tx_buf + 16, cipher_text, nwrite);
                memcpy(tx_buf + 16 + nwrite, sess_spi, 4);
                hmac_it(tx_buf, nwrite + 16 + 4, &val, &vlen, EVP_PKEY_new_mac_key(EVP_PKEY_HMAC, NULL, sess_key, sizeof(sess_key)));
                memcpy(tx_buf + 16 + nwrite + 4, val, 32);
                nwrite = sendto(net_fd, tx_buf, nwrite + 16 + 32 + 4, 0, (struct sockaddr *)&remote, sizeof(struct sockaddr));
            }
            else
            {
                nwrite = aes_encrypt(buffer, nread, sess_key, sess_iv, cipher_text);
                if (PRINT_DATA)
                {
                    printf("\ncipher_text:");
                    for (i = 0; i < nwrite; i++)
                        printf("%.02x", cipher_text[i]);
                    printf("\n");
                }

                //memcpy(sess_iv, cipher_text + nwrite - 16, 16);
                num_pkt++;
                if (PRINT_DATA)
                {
                    printf("\nNew sess_iv:");
                    for (i = 0; i < 16; i++)
                        printf("%.02x", sess_iv[i]);
                    printf("\n");
                }

                memcpy(tx_buf, cipher_text, nwrite);
                memcpy(tx_buf + nwrite, sess_spi, 4);
                hmac_it(tx_buf, nwrite + 4, &val, &vlen, EVP_PKEY_new_mac_key(EVP_PKEY_HMAC, NULL, sess_key, sizeof(sess_key)));
                memcpy(tx_buf + nwrite + 4, val, 32);
                nwrite = sendto(net_fd, tx_buf, nwrite + 32 + 4, 0, (struct sockaddr *)&remote, sizeof(struct sockaddr));
            }

            do_debug("\nTAP2NET %lu: Written %d bytes to the network\n", tap2net, nwrite);

            if (LOG_DATA)
            {
                printf("TAP2NET %lu: Encrypted data:", tap2net);
                for (i = 0; i < nwrite; i++)
                    printf("%.02x", tx_buf[i]);
                printf("\n");
            }

            struct key_ids key_ints_fin = key_to_int(sess_key);
            struct iv_ids iv_ints_fin = iv_to_int(sess_iv);
            vpn_peer_local = search_peer((uint32_t)inet_addr(inet_ntoa(ip_addr)), 1);

            delete_peer(vpn_peer_local, 1);
            delete_peer(vpn_peer_local2, 2);

            insert((uint32_t)inet_addr(inet_ntoa(ip_addr)), (uint32_t)inet_addr(dest_ip), peer_udp_port, num_pkt, spi_int, key_ints_fin.c1, key_ints_fin.c2, key_ints_fin.c3, key_ints_fin.c4, key_ints_fin.c5, key_ints_fin.c6, key_ints_fin.c7, key_ints_fin.c8, iv_ints_fin.c1, iv_ints_fin.c2, iv_ints_fin.c3, iv_ints_fin.c4, 1);
            insert((uint32_t)inet_addr(inet_ntoa(ip_addr)), (uint32_t)inet_addr(dest_ip), peer_udp_port, num_pkt, spi_int, key_ints_fin.c1, key_ints_fin.c2, key_ints_fin.c3, key_ints_fin.c4, key_ints_fin.c5, key_ints_fin.c6, key_ints_fin.c7, key_ints_fin.c8, iv_ints_fin.c1, iv_ints_fin.c2, iv_ints_fin.c3, iv_ints_fin.c4, 2);

            if (PRINT_HASHMAP)
            {
                // printf("NET2TAP HashMap: ");
                // display(1);
                printf("TAP2NET HashMap: ");
                display(2);
            }
        }

        if (FD_ISSET(net_fd, &rd_set))
        {
            /* data from the network: read it, and write it to the tun/tap interface.
             * We need to read the length first, and then the packet */

            net2tap++;

            /* read packet */
            nread = recvfrom(net_fd, buffer, sizeof(buffer), 0, rx, &rx_len);
            do_debug("\nNET2TAP %lu: Read %d bytes from the network\n", net2tap, nread);

            struct sockaddr_in *addr_in3 = (struct sockaddr_in *)rx;
            char *sp = inet_ntoa(addr_in3->sin_addr);
            // printf("IP packet received from address: %s %d\n", sp, ntohs(addr_in3->sin_port));

            if (PRINT_DATA)
            {
                printf("NET2TAP %lu: Encrypted data:", net2tap);
                for (i = 0; i < nread; i++)
                    printf("%.02x", buffer[i]);
                printf("\n");
            }

            // printf("\n-- update peers key and IV --\n");
            if (vpn_peer->conn_break)
            {
                vpn_peer_local = search_peer(vpn_peer->peer_ip, 1);
                vpn_peer_local2 = search_peer(vpn_peer->vpn_ip, 2);
                delete_peer(vpn_peer_local, 1);
                delete_peer(vpn_peer_local2, 2);
                vpn_peer->conn_break = 0;
                printf("Deleted entries from HashMap for peer %s\n", sp);
                continue;
            }
            else if (vpn_peer->del_all)
            {
                memset(hashArray, 0, SIZE1);
                memset(hashArray2, 0, SIZE2);
                vpn_peer->del_all = 0;
            }
            else if (vpn_peer->all_update || vpn_peer->key_update || vpn_peer->iv_update)
            {
                struct key_ids key_ints;
                struct iv_ids iv_ints;
                uint64_t spi_int;

                if (vpn_peer->all_update || vpn_peer->key_update)
                {
                    key_ints = key_to_int(vpn_peer->session_key);
                }
                if (vpn_peer->all_update || vpn_peer->iv_update)
                {
                    iv_ints = iv_to_int(vpn_peer->session_iv);
                }
                if (!vpn_peer->all_update)
                {
                    vpn_peer_local = search_peer(vpn_peer->peer_ip, 1);
                    vpn_peer_local2 = search_peer(vpn_peer->vpn_ip, 2);
                    if (vpn_peer->key_update)
                    {
                        iv_ints.c1 = vpn_peer_local2->cv1;
                        iv_ints.c2 = vpn_peer_local2->cv2;
                        iv_ints.c3 = vpn_peer_local2->cv3;
                        iv_ints.c4 = vpn_peer_local2->cv4;
                    }
                    else if (vpn_peer->iv_update)
                    {
                        key_ints.c1 = vpn_peer_local2->ck1;
                        key_ints.c2 = vpn_peer_local2->ck2;
                        key_ints.c3 = vpn_peer_local2->ck3;
                        key_ints.c4 = vpn_peer_local2->ck4;
                        key_ints.c5 = vpn_peer_local2->ck5;
                        key_ints.c6 = vpn_peer_local2->ck6;
                        key_ints.c7 = vpn_peer_local2->ck7;
                        key_ints.c8 = vpn_peer_local2->ck8;
                    }
                    spi_int = vpn_peer_local->spi_int;
                    delete_peer(vpn_peer_local, 1);
                    delete_peer(vpn_peer_local2, 2);
                }
                else if (vpn_peer->all_update)
                {
                    char *spi_temp;
                    asprintf(&spi_temp, "%.02x%.02x%.02x%.02x", vpn_peer->conn_spi[0], vpn_peer->conn_spi[1], vpn_peer->conn_spi[2], vpn_peer->conn_spi[3]);
                    spi_int = xtou64(spi_temp);
                }

                insert(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8, iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4, 1);
                insert(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints.c1, key_ints.c2, key_ints.c3, key_ints.c4, key_ints.c5, key_ints.c6, key_ints.c7, key_ints.c8, iv_ints.c1, iv_ints.c2, iv_ints.c3, iv_ints.c4, 2);

                if (PRINT_DATA)
                {
                    print_hashmap(vpn_peer->peer_ip, vpn_peer->vpn_ip, vpn_peer->peer_port, vpn_peer->num_pkt, spi_int, key_ints, iv_ints);
                }

                if (PRINT_HASHMAP)
                {
                    printf("NET2TAP HashMap: ");
                    display(1);
                    // printf("TAP2NET HashMap: ");
                    // display(2);
                }

                vpn_peer->key_update = 0;
                vpn_peer->iv_update = 0;
                vpn_peer->all_update = 0;
                vpn_peer->del_all = 0;
            }

            memcpy(sess_spi, buffer + nread - 32 - 4, 4);
            if (PRINT_DATA)
            {
                printf("\nSPI from received pkt:");
                for (i = 0; i < 4; i++)
                    printf("%.02x", sess_spi[i]);
                printf("\n");
            }
            char *spi_str;
            asprintf(&spi_str, "%.02x%.02x%.02x%.02x", sess_spi[0], sess_spi[1], sess_spi[2], sess_spi[3]);
            uint64_t spi_int = xtou64(spi_str);

            // printf("\n-- get peers key and IV for decryption --\n");
            vpn_peer_local = search_peer((uint32_t)inet_addr(inet_ntoa(addr_in3->sin_addr)), 1);
            if (vpn_peer_local == NULL)
            {
                // printf("Packet entry does not exist in the HashMap for %s; dropping the packet\n", sp);
                continue;
            }
            if (spi_int != vpn_peer_local->spi_int)
            {
                printf("SPI verification failed\n");
                continue;
            }

            struct in_addr ip_addr;
            ip_addr.s_addr = vpn_peer_local->vpn_ip;
            num_pkt = vpn_peer_local->num_pkt;
            uint16_t peer_udp_port = vpn_peer_local->peer_port;

            char *all_hex;
            size_t count;
            asprintf(&all_hex, "%08lx%08lx%08lx%08lx%08lx%08lx%08lx%08lx", vpn_peer_local->ck1, vpn_peer_local->ck2, vpn_peer_local->ck3, vpn_peer_local->ck4, vpn_peer_local->ck5, vpn_peer_local->ck6, vpn_peer_local->ck7, vpn_peer_local->ck8);
            char keystring[64];
            // strcpy(keystring, all_hex);
            memcpy(keystring, all_hex, 64);
            const char *key_pos = keystring;
            unsigned char key_val[32];
            for (count = 0; count < sizeof key_val / sizeof *key_val; count++)
            {
                sscanf(key_pos, "%2hhx", &key_val[count]);
                key_pos += 2;
            }
            memcpy(sess_key, key_val, 32);

            char *iv_hex;
            asprintf(&iv_hex, "%08lx%08lx%08lx%08lx", vpn_peer_local->cv1, vpn_peer_local->cv2, vpn_peer_local->cv3, vpn_peer_local->cv4);
            char ivstring[32];
            // strcpy(ivstring, iv_hex);
            memcpy(ivstring, iv_hex, 32);
            const char *iv_pos = ivstring;
            unsigned char iv_val[16];
            for (count = 0; count < sizeof iv_val / sizeof *iv_val; count++)
            {
                sscanf(iv_pos, "%2hhx", &iv_val[count]);
                iv_pos += 2;
            }
            memcpy(sess_iv, iv_val, 16);

            if (PRINT_DATA)
            {
                printf("\ndec sess_spi from map:");
                for (i = 0; i < 4; i++)
                    printf("%.02x", sess_spi[i]);
                printf("\n");

                printf("\ndec sess_key from map:");
                for (i = 0; i < 32; i++)
                    printf("%.02x", sess_key[i]);
                printf("\n");

                printf("\ndec sess_iv from map:");
                for (i = 0; i < 16; i++)
                    printf("%.02x", sess_iv[i]);
                printf("\n");
            }

            memcpy(hash_buf, buffer + nread - 32, 32);
            if (PRINT_DATA)
            {
                printf("\nhash_buf:");
                for (i = 0; i < 32; i++)
                    printf("%.02x", hash_buf[i]);
                printf("\n");
            }

            memcpy(data_buf, buffer, nread - 32);
            if (PRINT_DATA)
            {
                printf("\ndata_buf:");
                for (i = 0; i < nread - 32; i++)
                    printf("%.02x", data_buf[i]);
                printf("\n");
            }

            int hmac_res = 0;
            hmac_res = verify_it(data_buf, nread - 32, hash_buf, sig_len, EVP_PKEY_new_mac_key(EVP_PKEY_HMAC, NULL, sess_key, sizeof(sess_key)));
            if (hmac_res != 1)
            {
                // reset iv and key
                printf("HMAC Verification failed\n");
                continue;
            }

            if (num_pkt == 0)
            {
                //memcpy(sess_iv, buffer, 16);
                nwrite = decrypt(buffer + 16, nread - 32 - 16 - 4, sess_key, sess_iv, plain_text);
            }
            else
            {
                nwrite = decrypt(buffer, nread - 32 - 4, sess_key, sess_iv, plain_text);
            }

            //memcpy(sess_iv, buffer + nread - 32 - 4 - 16, 16);
            num_pkt++;
            if (PRINT_DATA)
            {
                printf("\nNew sess_iv:");
                for (i = 0; i < 16; i++)
                    printf("%.02x", sess_iv[i]);
                printf("\n");
            }

            struct sctpheader *sctp = (struct sctpheader *)(plain_text + 20);
            if (htons(sctp->sctp_srcport) != 38412 && htons(sctp->sctp_dstport) != 38412)
            {
                //continue;
            }

            cwrite(tap_fd, plain_text, nwrite);

            do_debug("\nNET2TAP %lu: Written %d bytes to the tap interface\n", net2tap, nwrite);

            if (LOG_DATA && nwrite != 0)
            {
                printf("NET2TAP %lu: Plaintext data:", net2tap);
                for (i = 0; i < nwrite; i++)
                    printf("%.02x", plain_text[i]);
                printf("\n");
            }

            struct key_ids key_ints_fin = key_to_int(sess_key);
            struct iv_ids iv_ints_fin = iv_to_int(sess_iv);
            vpn_peer_local2 = search_peer((uint32_t)inet_addr(inet_ntoa(ip_addr)), 2);

            delete_peer(vpn_peer_local, 1);
            delete_peer(vpn_peer_local2, 2);

            insert((uint32_t)inet_addr(inet_ntoa(addr_in3->sin_addr)), (uint32_t)inet_addr(inet_ntoa(ip_addr)), peer_udp_port, num_pkt, spi_int, key_ints_fin.c1, key_ints_fin.c2, key_ints_fin.c3, key_ints_fin.c4, key_ints_fin.c5, key_ints_fin.c6, key_ints_fin.c7, key_ints_fin.c8, iv_ints_fin.c1, iv_ints_fin.c2, iv_ints_fin.c3, iv_ints_fin.c4, 1);
            insert((uint32_t)inet_addr(inet_ntoa(addr_in3->sin_addr)), (uint32_t)inet_addr(inet_ntoa(ip_addr)), peer_udp_port, num_pkt, spi_int, key_ints_fin.c1, key_ints_fin.c2, key_ints_fin.c3, key_ints_fin.c4, key_ints_fin.c5, key_ints_fin.c6, key_ints_fin.c7, key_ints_fin.c8, iv_ints_fin.c1, iv_ints_fin.c2, iv_ints_fin.c3, iv_ints_fin.c4, 2);

            if (PRINT_HASHMAP)
            {
                printf("NET2TAP HashMap: ");
                display(1);
                // printf("TAP2NET HashMap: ");
                // display(2);
            }
        }
    }
}

int main(int argc, char *argv[])
{

    int tap_fd, option;
    int flags = IFF_TUN;
    char if_name[IFNAMSIZ] = "";
    int header_len = IP_HDR_LEN;
    struct sockaddr_in local, remote;
    char remote_ip[16] = "";
    unsigned short int port = PORT;
    int sock_fd, net_fd, optval = 1;
    socklen_t remotelen;
    int cliserv = -1; /* must be specified on cmd line */

    long res = 1;
    SSL_CTX *ctx = NULL;
    const SSL_METHOD *method;
    SSL *ssl = NULL;
    int ssl_error;
    char *ca_cert, *cert_file, *key_file, *my_vpn_ip;
    uint16_t my_udp_port = 12345;
    uint8_t BONUS = 1;

    progname = argv[0];

    /* Check command line options */
    while ((option = getopt(argc, argv, "i:sc:p:e:r:m:k:v:l:b:uahd")) > 0)
    {
        switch (option)
        {
        case 'd':
            debug = 1;
            break;
        case 'h':
            usage();
            break;
        case 'r':
            ca_cert = strdup(optarg);
            break;
        case 'm':
            cert_file = strdup(optarg);
            break;
        case 'k':
            key_file = strdup(optarg);
            break;
        case 'v':
            my_vpn_ip = strdup(optarg);
            break;
        case 'l':
            my_udp_port = atoi(optarg);
            break;
        case 'b':
            BONUS = atoi(optarg);
            break;
        case 'i':
            strncpy(if_name, optarg, IFNAMSIZ - 1);
            break;
        case 's':
            cliserv = SERVER;
            break;
        case 'c':
            cliserv = CLIENT;
            strncpy(remote_ip, optarg, 15);
            break;
        case 'p':
            port = atoi(optarg);
            break;
        case 'u':
            flags = IFF_TUN;
            break;
        case 'a':
            flags = IFF_TAP;
            header_len = ETH_HDR_LEN;
            break;
        default:
            my_err("Unknown option %c\n", option);
            usage();
        }
    }

    argv += optind;
    argc -= optind;

    if (argc > 0)
    {
        my_err("Too many options!\n");
        usage();
    }

    if (*if_name == '\0')
    {
        my_err("Must specify interface name!\n");
        usage();
    }
    else if (cliserv < 0)
    {
        my_err("Must specify client or server mode!\n");
        usage();
    }
    else if ((cliserv == CLIENT) && (*remote_ip == '\0'))
    {
        my_err("Must specify server address!\n");
        usage();
    }

    /* initialize tun/tap interface */
    if ((tap_fd = tun_alloc(if_name, flags | IFF_NO_PI)) < 0)
    {
        my_err("Error connecting to tun/tap interface %s!\n", if_name);
        exit(1);
    }

    do_debug("Successfully connected to interface %s\n", if_name);

    if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        perror("socket()");
        exit(1);
    }

    if (cliserv == CLIENT)
    {
        int mem_id;

        mem_id = shmget(IPC_PRIVATE, 10 * sizeof(struct vpn_client), SHM_R | SHM_W);
        struct vpn_client *x;
        struct vpn_client *y;
        struct vpn_client *list;

        /* Server, wait for connections */
        pid_t cpid = fork();
        if (cpid == 0)
        {
            list = (struct vpn_client *)shmat(mem_id, NULL, 0);
            if ((void *)-1 == (void *)list)
            {
                perror("Child cannot attach");
                exit(1);
            }
            x = list;
            send_recv_udp(tap_fd, x, my_udp_port);
        }
        else
        {
            // pid_t cpid2 = fork();
            if (1)
            {
                list = (struct vpn_client *)shmat(mem_id, NULL, 0);
                if ((void *)list == (void *)-1)
                {
                    perror("Child cannot attach");
                    exit(1);
                }

                /* Client, try to connect to server */

                /* assign the destination address */
                memset(&remote, 0, sizeof(remote));
                remote.sin_family = AF_INET;
                remote.sin_addr.s_addr = inet_addr(remote_ip);
                remote.sin_port = htons(port);

                /* connection request */
                if (connect(sock_fd, (struct sockaddr *)&remote, sizeof(remote)) < 0)
                {
                    perror("connect()");
                    exit(1);
                }

                net_fd = sock_fd;

                method = TLS_client_method();
                ctx = create_context(method);
                SSL_CTX_set_min_proto_version(ctx, TLS1_3_VERSION);
                configure_verify_context(ctx, ca_cert, cert_file, key_file);
                ssl = SSL_new(ctx); /* create new SSL connection state */
                const char *const PREFERRED_CIPHERS = "HIGH:!aNULL:!PSK:!SRP:!MD5:!RC4:@STRENGTH";
                res = SSL_set_cipher_list(ssl, PREFERRED_CIPHERS);
                if (!(1 == res))
                    handleErrors();
                SSL_set_fd(ssl, net_fd); /* attach the socket descriptor */
                ssl_error = SSL_connect(ssl);
                if (ssl_error == FAIL) /* perform the connection */
                {
                    handleErrors();
                }
                show_certs(ssl);
                do_debug("\nCLIENT: Successfully setup the SSL session\n");

                do_debug("CLIENT: Connected to server %s\n", inet_ntoa(remote.sin_addr));

                int i, j;
                char selfiv[16];
                char selfkey[32];
                char spi[4];
                char buffer[BUFSIZE];
                uint16_t nread, nwrite;

                sprintf(buffer, "%01d", 0);
                nwrite = SSL_write(ssl, buffer, 1);
                memset(buffer, 0, BUFSIZE);

                // key exchange
                RAND_bytes(selfkey, sizeof(selfkey));
                RAND_bytes(selfiv, sizeof(selfiv));
                RAND_bytes(spi, sizeof(spi));
                // struct hashmap *map = (struct hashmap *)shmem;

                j = 0;
                for (i = 0; i < sizeof(selfkey); i++)
                {
                    buffer[j++] = selfkey[i];
                }
                for (i = 0; i < sizeof(selfiv); i++)
                {
                    buffer[j++] = selfiv[i];
                }
                for (i = 0; i < sizeof(spi); i++)
                {
                    buffer[j++] = spi[i];
                }
                nwrite = SSL_write(ssl, buffer, j);
                memset(buffer, 0, BUFSIZE);

                nread = SSL_read(ssl, buffer, BUFSIZE);

                for (i = 0; i < sizeof(session_key); i++)
                {
                    session_key[i] = buffer[i] ^ selfkey[i];
                }
                for (i = 0; i < sizeof(session_iv); i++)
                {
                    session_iv[i] = buffer[i + sizeof(session_key)] ^ selfiv[i];
                }
                for (i = 0; i < sizeof(peer_spi); i++)
                {
                    peer_spi[i] = buffer[i + sizeof(session_key) + sizeof(session_iv)] ^ spi[i];
                }
                memset(buffer, 0, BUFSIZE);

                sprintf(buffer, "%05d", my_udp_port);
                nwrite = SSL_write(ssl, buffer, 5);
                memset(buffer, 0, BUFSIZE);

                nread = SSL_read(ssl, buffer, BUFSIZE);
                uint16_t peer_udp_port = atoi(buffer);
                printf("Peer UDP Port is %d\n", peer_udp_port);
                memset(buffer, 0, BUFSIZE);

                sprintf(buffer, "%010d", (uint32_t)inet_addr(my_vpn_ip));
                nwrite = SSL_write(ssl, buffer, 10);
                memset(buffer, 0, BUFSIZE);

                nread = SSL_read(ssl, buffer, BUFSIZE);
                uint32_t int_vpn_ip = atoi(buffer);
                // printf("int_vpn_ip is %d\n", int_vpn_ip);
                memset(buffer, 0, BUFSIZE);

                struct in_addr ip_addr2;
                ip_addr2.s_addr = int_vpn_ip;
                printf("VPN IP of Peer received from SSL %s\n", inet_ntoa(ip_addr2));

                y = list;
                if (y->all_update != 1 && y->key_update != 1 && y->iv_update != 1 && y->conn_break != 1)
                {
                    y->num_pkt = 0;
                    y->vpn_ip = int_vpn_ip;
                    y->peer_ip = (uint32_t)inet_addr(inet_ntoa(remote.sin_addr));
                    y->peer_port = peer_udp_port;
                    memcpy(y->conn_spi, peer_spi, 4);
                    memcpy(y->session_key, session_key, 32);
                    memcpy(y->session_iv, session_iv, 16);
                    y->all_update = 1;
                    y->key_update = 0;
                    y->iv_update = 0;
                    y->conn_break = 0;
                }
            }
        }
    }
    else
    {
        int mem_id;

        mem_id = shmget(IPC_PRIVATE, 10 * sizeof(struct vpn_client), SHM_R | SHM_W);
        struct vpn_client *x;
        struct vpn_client *y;
        struct vpn_client *list;

        /* Server, wait for connections */
        // struct hashmap *map = hashmap_new(sizeof(struct vpn_client), 0, 0, 0, peer_hash, peer_compare, NULL, NULL);
        pid_t cpid = fork();
        if (cpid == 0)
        {
            list = (struct vpn_client *)shmat(mem_id, NULL, 0);
            if ((void *)-1 == (void *)list)
            {
                perror("Child cannot attach");
                exit(1);
            }
            x = list;
            send_recv_udp(tap_fd, x, my_udp_port);
        }
        else
        {
            list = (struct vpn_client *)shmat(mem_id, NULL, 0);
            if ((void *)list == (void *)-1)
            {
                perror("Child cannot attach");
                exit(1);
            }
            /* avoid EADDRINUSE error on bind() */
            if (setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, (char *)&optval, sizeof(optval)) < 0)
            {
                perror("setsockopt()");
                exit(1);
            }

            memset(&local, 0, sizeof(local));
            local.sin_family = AF_INET;
            local.sin_addr.s_addr = htonl(INADDR_ANY);
            local.sin_port = htons(port);
            if (bind(sock_fd, (struct sockaddr *)&local, sizeof(local)) < 0)
            {
                perror("bind()");
                exit(1);
            }

            if (listen(sock_fd, 5) < 0)
            {
                perror("listen()");
                exit(1);
            }

            method = TLS_server_method();
            ctx = create_context(method);
            SSL_CTX_set_min_proto_version(ctx, TLS1_3_VERSION);
            configure_verify_context(ctx, ca_cert, cert_file, key_file);
            pid_t sslpid;
            for (;;)
            {
                /* wait for connection request */
                remotelen = sizeof(remote);
                memset(&remote, 0, remotelen);
                if ((net_fd = accept(sock_fd, (struct sockaddr *)&remote, &remotelen)) < 0)
                {
                    perror("accept()");
                    exit(1);
                }

                ssl = SSL_new(ctx); /* create new SSL connection state */
                const char *const PREFERRED_CIPHERS = "HIGH:!aNULL:!PSK:!SRP:!MD5:!RC4:@STRENGTH";
                res = SSL_set_cipher_list(ssl, PREFERRED_CIPHERS);
                if (!(1 == res))
                    handleErrors();
                SSL_set_fd(ssl, net_fd); /* attach the socket descriptor */
                ssl_error = SSL_accept(ssl);
                if (ssl_error == FAIL) /* perform the connection */
                {
                    handleErrors();
                }
                show_certs(ssl);
                do_debug("\nSERVER: Successfully setup the SSL session with a new client\n");

                do_debug("SERVER: Client connected from %s\n", inet_ntoa(remote.sin_addr));

                uint32_t peer_ip = (uint32_t)inet_addr(inet_ntoa(remote.sin_addr));

                sslpid = fork();
                if (sslpid == 0)
                {
                    int i, j;
                    char selfiv[16];
                    char selfkey[32];
                    char spi[4];
                    char buffer[BUFSIZE];
                    uint16_t nread, nwrite;
                    uint8_t cmd_flag;
                    int count = 0;
                    struct vpn_client vpn_server_peer;

                    if (1)
                    {
                        memset(buffer, 0, BUFSIZE);
                        nread = SSL_read(ssl, buffer, BUFSIZE);
                        if (nread > 0)
                        {
                            cmd_flag = atoi(buffer);
                            memset(buffer, 0, BUFSIZE);
                            if (cmd_flag == 0)
                            {
                                printf("\nReceived command ID %d which is create new connection\n", cmd_flag);
                                // key exchange
                                RAND_bytes(selfkey, sizeof(selfkey));
                                RAND_bytes(selfiv, sizeof(selfiv));
                                RAND_bytes(spi, sizeof(spi));

                                j = 0;
                                for (i = 0; i < sizeof(selfkey); i++)
                                {
                                    buffer[j++] = selfkey[i];
                                }
                                for (i = 0; i < sizeof(selfiv); i++)
                                {
                                    buffer[j++] = selfiv[i];
                                }
                                for (i = 0; i < sizeof(spi); i++)
                                {
                                    buffer[j++] = spi[i];
                                }
                                nwrite = SSL_write(ssl, buffer, j);
                                memset(buffer, 0, BUFSIZE);

                                nread = SSL_read(ssl, buffer, BUFSIZE);

                                for (i = 0; i < sizeof(session_key); i++)
                                {
                                    session_key[i] = buffer[i] ^ selfkey[i];
                                }
                                for (i = 0; i < sizeof(session_iv); i++)
                                {
                                    session_iv[i] = buffer[i + sizeof(session_key)] ^ selfiv[i];
                                }
                                for (i = 0; i < sizeof(peer_spi); i++)
                                {
                                    peer_spi[i] = buffer[i + sizeof(session_key) + sizeof(session_iv)] ^ spi[i];
                                }
                                memset(buffer, 0, BUFSIZE);

                                sprintf(buffer, "%05d", my_udp_port);
                                nwrite = SSL_write(ssl, buffer, 5);
                                memset(buffer, 0, BUFSIZE);

                                nread = SSL_read(ssl, buffer, BUFSIZE);
                                uint16_t peer_udp_port = atoi(buffer);
                                printf("Peer UDP Port is %d\n", peer_udp_port);
                                memset(buffer, 0, BUFSIZE);

                                sprintf(buffer, "%010d", (uint32_t)inet_addr(my_vpn_ip));
                                nwrite = SSL_write(ssl, buffer, 10);
                                memset(buffer, 0, BUFSIZE);

                                nread = SSL_read(ssl, buffer, BUFSIZE);
                                uint32_t int_vpn_ip = atoi(buffer);
                                // printf("int_vpn_ip is %d\n", int_vpn_ip);
                                memset(buffer, 0, BUFSIZE);

                                struct in_addr ip_addr2;
                                ip_addr2.s_addr = int_vpn_ip;
                                printf("VPN IP of Peer received from SSL %s\n", inet_ntoa(ip_addr2));

                                vpn_server_peer.peer_ip = peer_ip;
                                vpn_server_peer.peer_port = peer_udp_port;
                                vpn_server_peer.vpn_ip = int_vpn_ip;
                                memcpy(vpn_server_peer.conn_spi, peer_spi, 4);
                                memcpy(vpn_server_peer.session_key, session_key, 32);
                                memcpy(vpn_server_peer.session_iv, session_iv, 16);

                                y = list;
                                if (y->all_update != 1 && y->key_update != 1 && y->iv_update != 1 && y->conn_break != 1)
                                {
                                    y->num_pkt = 0;
                                    y->vpn_ip = int_vpn_ip;
                                    y->peer_ip = peer_ip;
                                    y->peer_port = peer_udp_port;
                                    memcpy(y->conn_spi, peer_spi, 4);
                                    memcpy(y->session_key, session_key, 32);
                                    memcpy(y->session_iv, session_iv, 16);
                                    y->all_update = 1;
                                    y->key_update = 0;
                                    y->iv_update = 0;
                                    y->conn_break = 0;
                                    y->del_all = 0;
                                }
                            }
                        }
                    }
                }
            }
            if (sslpid != 0)
            {
                y = list;
                y->del_all = 1;
                sleep(5);
                kill(cpid, SIGTERM);
                int loop;
                bool died = false;
                for (loop = 0; !died && loop < 5; ++loop)
                {
                    int status;
                    pid_t id;
                    sleep(1);
                    if (waitpid(cpid, &status, WNOHANG) == cpid)
                        died = true;
                }
                if (!died)
                    kill(cpid, SIGKILL);
                while (wait(NULL) > 0)
                    ;
            }
        }
    }
    return (0);
}