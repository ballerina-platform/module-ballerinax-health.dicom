/*
 * Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerinax.health.dicom;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BString;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Utility class for converting Ballerina numeric byte arrays to integers or floats and vice versa.
 */
public class ByteUtils {

    /**
     * Private constructor to prevent instantiation of this utility class.
     */
    private ByteUtils() {
    }

    /**
     * Converts a Ballerina byte array representing an integer to an integer value.
     *
     * @param bArray    the Ballerina byte array containing the integer bytes
     * @param byteOrder the Ballerina string specifying the byte order
     * @return the converted integer value
     * @throws InvalidByteOrderException if the provided byte order is an invalid byte order
     */
    public static int bytesToInt(BArray bArray, BString byteOrder) throws InvalidByteOrderException {
        return constructByteBufferForBytesToNumberOperation(bArray, byteOrder, Integer.BYTES).getInt();
    }

    /**
     * Converts a Ballerina byte array representing a float to a float value.
     *
     * @param bArray    the Ballerina byte array containing the float bytes
     * @param byteOrder the Ballerina string specifying the byte order
     * @return the converted float value
     * @throws InvalidByteOrderException if the provided byte order is an invalid byte order
     */
    public static float bytesToFloat(BArray bArray, BString byteOrder) throws InvalidByteOrderException {
        return constructByteBufferForBytesToNumberOperation(bArray, byteOrder, Float.BYTES).getFloat();
    }

    /**
     * Converts an integer value to a Ballerina byte array representation.
     *
     * @param n         the integer value to be converted
     * @param byteOrder the Ballerina string specifying the byte order
     * @return the converted Ballerina byte array
     * @throws InvalidByteOrderException if the provided byte order is an invalid byte order
     */
    public static BArray intToBytes(int n, BString byteOrder) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        byte[] bytes = ByteBuffer.allocate(Integer.BYTES).order(order).putInt(n).array();
        return ValueCreator.createArrayValue(bytes);
    }

    /**
     * Converts a float value to a Ballerina byte array representation.
     *
     * @param n         the float value to be converted
     * @param byteOrder the Ballerina string specifying the byte order
     * @return the converted Ballerina byte array
     * @throws InvalidByteOrderException if the provided byte order is an invalid byte order
     */
    public static BArray floatToBytes(float n, BString byteOrder) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        byte[] bytes = ByteBuffer.allocate(Float.BYTES).order(order).putFloat(n).array();
        return ValueCreator.createArrayValue(bytes);
    }

    /**
     * Resizes a Ballerina numeric byte array to a specified length, respecting the byte order.
     *
     * @param bArray    the Ballerina byte array containing numeric data
     * @param byteOrder the Ballerina string specifying the byte order
     * @param newLength the desired new length of the byte array
     * @return the resized byte array
     * @throws InvalidByteOrderException if the provided byte order is an invalid byte order
     */
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

    /**
     * Constructs a ByteBuffer suitable for bytes to number operations.
     *
     * @param bArray    the input Ballerina byte array
     * @param byteOrder the Ballerina string specifying the byte order
     * @param byteSize  the size of the byte array
     * @return a ByteBuffer configured with the provided byte array, byte order, and size
     * @throws InvalidByteOrderException if an invalid byte order is encountered
     */
    private static ByteBuffer constructByteBufferForBytesToNumberOperation(BArray bArray, BString byteOrder, int byteSize) throws InvalidByteOrderException {
        ByteOrder order = getByteOrder(byteOrder);
        if (bArray.getLength() < byteSize) {
            bArray = resizeNumericByteArray(bArray, byteOrder, byteSize);
        }
        byte[] bytes = bArray.getByteArray();
        int offset = (bytes.length > byteSize && order == ByteOrder.BIG_ENDIAN) ? bytes.length - byteSize : 0;
        return ByteBuffer.wrap(bytes, offset, byteSize).order(order);
    }

    /**
     * Retrieves the ByteOrder enum value based on the provided byte order Ballerina string.
     *
     * @param byteOrder the byte order Ballerina string
     * @return the corresponding ByteOrder enum value
     * @throws InvalidByteOrderException if an invalid byte order string is provided
     */
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
