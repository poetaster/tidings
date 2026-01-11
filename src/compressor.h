#ifndef COMPRESSOR_H
#define COMPRESSOR_H

#include <QByteArray>

class Compressor
{
public:
    Compressor() = default;

    static bool gzip(QByteArray input, QByteArray &output, int level = 9);
    static QByteArray gunzip(const QByteArray &data);
};

#endif // COMPRESSOR_H
