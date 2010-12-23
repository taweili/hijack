/*
 */

/*
 */

interface HiJack {
    /**
     * Sends one byte over the HiJack link.
     *
     * @param byte The byte to send.
     * @return SUCCESS if byte will be sent.
     */
    async command error_t send( uint8_t byte);

    /**
     * Signal that the byte send is done.
     *
     * @param byte Byte that was sent.
     * @param error SUCCESS if the transmission was successful, FAIL
     * otherwise.
     */
    async event void sendDone( uint8_t byte, error_t error );

    /**
     * Signal that a byte was received.
     *
     * @param byte Received byte.
     */
    async event void receive( uint8_t byte);

}


