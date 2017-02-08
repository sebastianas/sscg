/*
    This file is part of sscg.

    sscg is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    sscg is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with sscg.  If not, see <http://www.gnu.org/licenses/>.

    Copyright 2017 by Stephen Gallagher <sgallagh@redhat.com>
*/

#include "include/sscg.h"
#include "include/authority.h"
#include "include/x509.h"
#include "include/key.h"

int
create_private_CA(TALLOC_CTX *mem_ctx, const struct sscg_options *options,
                  struct sscg_x509_cert **_cacert)
{
    int ret;
    int bits;
    struct sscg_bignum *e;
    struct sscg_bignum *serial;
    struct sscg_cert_info *ca_certinfo;
    struct sscg_x509_req *csr;
    struct sscg_evp_pkey *pkey;
    struct sscg_x509_cert *cert;


    TALLOC_CTX *tmp_ctx = talloc_new(NULL);
    if (!tmp_ctx) {
        return ENOMEM;
    }

    ca_certinfo = sscg_cert_info_new(tmp_ctx, options->hash_fn);
    CHECK_MEM(ca_certinfo);

    /* Populate cert_info from options */
    ca_certinfo->country = talloc_strdup(ca_certinfo, options->country);
    CHECK_MEM(ca_certinfo->country);

    ca_certinfo->state = talloc_strdup(ca_certinfo, options->state);
    CHECK_MEM(ca_certinfo->state);

    ca_certinfo->locality = talloc_strdup(ca_certinfo, options->locality);
    CHECK_MEM(ca_certinfo->locality);

    ca_certinfo->org = talloc_strdup(ca_certinfo, options->org);
    CHECK_MEM(ca_certinfo->org);

    ca_certinfo->org_unit = talloc_strdup(ca_certinfo, options->org_unit);
    CHECK_MEM(ca_certinfo->org_unit);

    ca_certinfo->cn = talloc_strdup(ca_certinfo, options->hostname);
    CHECK_MEM(ca_certinfo->cn);

    /* TODO: include subject alt names */

    /* For the private CA, we always use 4096 bits and an exponent
       value of RSA F4 aka 0x10001 (65537) */
    bits = 4096;
    ret = sscg_init_bignum(tmp_ctx, RSA_F4, &e);
    CHECK_OK(ret);

    /* Generate an RSA keypair for this CA */
    /* TODO: support DSA keys as well */
    ret = sscg_generate_rsa_key(ca_certinfo, bits, e, &pkey);
    CHECK_OK(ret);

    /* Create a certificate signing request for the private CA */
    ret = sscg_create_x509v3_csr(tmp_ctx, ca_certinfo, pkey, &csr);
    CHECK_OK(ret);

    /* create a serial number for this certificate */
    ret = sscg_generate_serial(tmp_ctx, &serial);

    /* Self-sign the private CA */
    ret = sscg_sign_x509_csr(tmp_ctx, csr, serial, options->lifetime,
                             NULL, pkey, options->hash_fn, &cert);
    CHECK_OK(ret);

    *_cacert = talloc_steal(mem_ctx, cert);

    ret = EOK;

done:
    talloc_zfree(tmp_ctx);
    return ret;
}
