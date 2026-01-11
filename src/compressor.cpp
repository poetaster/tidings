#include "compressor.h"

#include <zlib.h>

constexpr int GZIP_WINDOWS_BIT = 15 + 16;
constexpr int GZIP_CHUNK_SIZE = 32 * 1024;

bool Compressor::gzip(QByteArray input, QByteArray &output, int level)
{
    output.clear();

    if (input.isEmpty()) {
        return true;
    }

    int flush{0};

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = Z_NULL;
    strm.next_in = Z_NULL;

    int ret = deflateInit2(&strm, qMax(-1, qMin(9, level)), Z_DEFLATED, GZIP_WINDOWS_BIT, 8, Z_DEFAULT_COMPRESSION);

    if (ret != Z_OK) {
        return false;
    }

    char *input_data = input.data();
    int input_data_left = input.length();

    do {
        int chunk_size = qMin(GZIP_CHUNK_SIZE, input_data_left);

        strm.next_in = (unsigned char*)input_data;
        strm.avail_in = chunk_size;

        input_data += chunk_size;
        input_data_left -= chunk_size;

        flush = (input_data_left <= 0 ? Z_FINISH : Z_NO_FLUSH);

        do {
            char out[GZIP_CHUNK_SIZE];

            strm.next_out = (unsigned char*)out;
            strm.avail_out = GZIP_CHUNK_SIZE;

            ret = deflate(&strm, flush);

            if(ret == Z_STREAM_ERROR)
            {
                deflateEnd(&strm);

                return false;
            }

            int have = (GZIP_CHUNK_SIZE - strm.avail_out);

            if(have > 0)
                output.append((char*)out, have);

        } while (strm.avail_out == 0);

        deflateEnd(&strm);

    } while (flush != Z_FINISH);

    return true;
}

QByteArray Compressor::gunzip(const QByteArray &data)
{
    if (data.size() <= 4) {
            return data;
        }

        QByteArray result;

        int ret{0};
        z_stream strm;
        static const int CHUNK_SIZE = 1024;
        char out[CHUNK_SIZE];

        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.avail_in = data.size();
        strm.next_in = (Bytef*)(data.data());

        ret = inflateInit2(&strm, GZIP_WINDOWS_BIT);
        if (ret != Z_OK)
            return data;

        do {
            strm.avail_out = CHUNK_SIZE;
            strm.next_out = (Bytef*)(out);

            ret = inflate(&strm, Z_NO_FLUSH);
            Q_ASSERT(ret != Z_STREAM_ERROR);

            switch (ret) {
            case Z_NEED_DICT:
                ret = Z_DATA_ERROR;
            case Z_DATA_ERROR:
            case Z_MEM_ERROR:
                (void)inflateEnd(&strm);
                return data;
            }

            result.append(out, CHUNK_SIZE - strm.avail_out);
        } while (strm.avail_out == 0);

        inflateEnd(&strm);
        return result;
}
