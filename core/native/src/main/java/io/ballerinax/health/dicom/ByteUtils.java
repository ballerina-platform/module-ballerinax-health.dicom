package io.ballerinax.health.dicom;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BString;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Utility class for converting numeric byte arrays to integers or floats and vice versa.
 */
public class ByteUtils {
    public static int bytesToInt(BArray bArray, BString byteOrder) throws InvalidByteOrderException {
        return constructByteBufferForBytesToNumberOperation(bArray, byteOrder, Integer.BYTES).getInt();
    }

    public static float bytesToFloat(BArray bArray, BString byteOrder) throws InvalidByteOrderException {
        return constructByteBufferForBytesToNumberOperation(bArray, byteOrder, Float.BYTES).getFloat();
    }

    public static BArray intToBytes(int n, BString byteOrder) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        byte[] bytes = ByteBuffer.allocate(Integer.BYTES).order(order).putInt(n).array();
        return ValueCreator.createArrayValue(bytes);
    }

    public static BArray floatToBytes(float n, BString byteOrder) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        byte[] bytes = ByteBuffer.allocate(Float.BYTES).order(order).putFloat(n).array();
        return ValueCreator.createArrayValue(bytes);
    }

    public static BArray resizeNumericByteArray(BArray bArray, BString byteOrder, int newLength) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        byte[] array = bArray.getByteArray();

        if (array.length >= newLength) {
            return bArray;
        }

        ByteBuffer buffer = ByteBuffer.allocate(newLength);
        buffer.order(order);

        if (order == ByteOrder.LITTLE_ENDIAN) {
            buffer.put(array, 0, Math.min(array.length, newLength));
        } else {
            buffer.position(newLength - array.length);
            buffer.put(array);
        }

        return ValueCreator.createArrayValue(buffer.array());
    }

    private static ByteBuffer constructByteBufferForBytesToNumberOperation(BArray bArray, BString byteOrder, int byteSize) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        if (bArray.getLength() < byteSize) {
            bArray = resizeNumericByteArray(bArray, byteOrder, byteSize);
        }
        byte[] bytes = bArray.getByteArray();
        int offset = (bytes.length > byteSize && order == ByteOrder.BIG_ENDIAN) ? bytes.length - byteSize : 0;
        return ByteBuffer.wrap(bytes, offset, byteSize).order(order);
    }

    private static ByteOrder getByteOrder(BString byteOrder) throws InvalidByteOrderException {
        if (byteOrder.getValue().equals(ByteOrder.LITTLE_ENDIAN.toString())) {
            return ByteOrder.LITTLE_ENDIAN;
        } else if (byteOrder.getValue().equals(ByteOrder.BIG_ENDIAN.toString())) {
            return ByteOrder.BIG_ENDIAN;
        } else {
            throw new InvalidByteOrderException("Invalid byte order");
        }
    }
}
