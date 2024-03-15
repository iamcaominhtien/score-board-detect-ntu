package com.example.native_python

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class ConvertYUV {
    private object YuvConverter {
        /**
         * Converts an NV21 image into JPEG compressed.
         * @param nv21 byte[] of the input image in NV21 format
         * @param width Width of the image.
         * @param height Height of the image.
         * @param quality Quality of compressed image(0-100)
         * @return byte[] of a compressed Jpeg image.
         */
        fun NV21toJPEG(nv21: ByteArray?, width: Int, height: Int, quality: Int): ByteArray {
            val out = ByteArrayOutputStream()
            val yuv = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            yuv.compressToJpeg(Rect(0, 0, width, height), quality, out)
            return out.toByteArray()
        }

        /**
         * Format YUV_420 planes in to NV21.
         * Removes strides from planes and combines the result to single NV21 byte array.
         * @param planes  List of Bytes list
         * @param strides contains the strides of each plane. The structure :
         * strideRowFirstPlane,stridePixelFirstPlane, strideRowSecondPlane
         * @param width   Width of the image
         * @param height  Height of given image
         * @return NV21 image byte[].
         */
        fun YUVtoNV21(
            planes: List<ByteArray?>,
            strides: IntArray,
            width: Int,
            height: Int
        ): ByteArray {
            val crop = Rect(0, 0, width, height)
            val format = ImageFormat.YUV_420_888
            val data = ByteArray(width * height * ImageFormat.getBitsPerPixel(format) / 8)
            val rowData = ByteArray(strides[0])
            var channelOffset = 0
            var outputStride = 1
            for (i in planes.indices) {
                when (i) {
                    0 -> {
                        channelOffset = 0
                        outputStride = 1
                    }

                    1 -> {
                        channelOffset = width * height + 1
                        outputStride = 2
                    }

                    2 -> {
                        channelOffset = width * height
                        outputStride = 2
                    }
                }
                val buffer = planes[i]?.let { ByteBuffer.wrap(it) }
                var rowStride: Int
                var pixelStride: Int
                if (i == 0) {
                    rowStride = strides[i]
                    pixelStride = strides[i + 1]
                } else {
                    rowStride = strides[i * 2]
                    pixelStride = strides[i * 2 + 1]
                }
                val shift = if (i == 0) 0 else 1
                val w = width shr shift
                val h = height shr shift
                buffer?.position(rowStride * (crop.top shr shift) + pixelStride * (crop.left shr shift))
                for (row in 0 until h) {
                    var length: Int
                    if (pixelStride == 1 && outputStride == 1) {
                        length = w
                        buffer?.get(data, channelOffset, length)
                        channelOffset += length
                    } else {
                        length = (w - 1) * pixelStride + 1
                        buffer?.get(rowData, 0, length)
                        for (col in 0 until w) {
                            data[channelOffset] = rowData[col * pixelStride]
                            channelOffset += outputStride
                        }
                    }
                    if (row < h - 1) {
                        buffer?.position(buffer.position() + rowStride - length)
                    }
                }
            }
            return data
        }
    }


    fun convertYUVToGRB(bytesList: List<ByteArray?>, strides: IntArray, width: Int, height: Int): ByteArray {
        try {
            val data: ByteArray = YuvConverter.NV21toJPEG(
                YuvConverter.YUVtoNV21(bytesList, strides, width, height),
                width,
                height,
                100
            )
            val bitmapRaw = BitmapFactory.decodeByteArray(data, 0, data.size)
            val matrix = Matrix()
            matrix.postRotate(90f)
            val finalBitmap = Bitmap.createBitmap(
                bitmapRaw,
                0,
                0,
                bitmapRaw.width,
                bitmapRaw.height,
                matrix,
                true
            )
            val outputStreamCompressed = ByteArrayOutputStream()
            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 60, outputStreamCompressed)
            val result = outputStreamCompressed.toByteArray()
            outputStreamCompressed.close()
            return result
        } catch (e: Exception) {
            e.printStackTrace()
            throw RuntimeException("Error converting NV21 to JPEG", e)
        }
    }
}