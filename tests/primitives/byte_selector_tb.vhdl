context work.tb_context;

entity ByteSelector_TB is
    generic (
        runner_cfg: string;
        byte_size, log_n_bytes: positive
    );
end;

architecture tb of ByteSelector_TB is
    constant n_bytes: positive := 2**log_n_bytes;

    signal bytes_in, word_in, bytes_out, word_out:
        std_ulogic_vector(byte_size * n_bytes - 1 downto 0);
    signal addr, bw: unsigned(log_n_bytes - 1 downto 0) := (others => '0');
    signal byte_enable: std_ulogic_vector(n_bytes - 1 downto 0);
    signal sign_extend: std_ulogic;
begin
    dut: entity src.ByteSelector
        generic map (byte_size, log_n_bytes)
        port map(bytes_in, word_in, bytes_out, word_out, addr, bw, sign_extend, byte_enable);

    main: process
        variable rnd: RandomPType;
        constant ZERO: word_out'subtype := (others => '0');
        variable size: positive;
        variable offset: natural;
        variable pow: natural range 0 to bw'high + 1;
        variable v_addr: unsigned(addr'high + 1 downto 0);
        variable res_bytes, res_word: word_in'subtype;
    begin
        test_runner_setup(runner, runner_cfg);
        for i in 1 to 1000 loop
            -- Generate test case
            v_addr := '0' & rnd.RandUnsigned(addr'high + 1);
            addr <= v_addr(addr'range);
            pow := rnd.RandInt(0, pow'high);
            size := 2**pow;
            offset := to_integer(v_addr(v_addr'high downto pow)) * size;
            bw <= to_unsigned(2**pow - 1, bw'high + 1);
            word_in <= rnd.RandSlv(word_in'high + 1);
            bytes_in <= (others => '0');
            sign_extend <= '0';
            wait for 2 us;
            -- Validate bytes_out
            size := size * byte_size;
            offset := offset * byte_size;
            res_bytes := (others => '0');
            res_bytes(size + offset - 1 downto offset) := word_in(size - 1 downto 0);
            check_equal(bytes_out, res_bytes, "Check bytes out");
            check_equal(word_out, ZERO, "Check word out (zero)");
            -- Copy bytes_out to bytes_in, filling other bits randomly
            bytes_in <= rnd.RandSlv(bytes_in'high + 1);
            bytes_in(size + offset - 1 downto offset) <= word_in(size - 1 downto 0);
            wait for 2 us;
            -- Validate word_out (unsigned)
            check_equal(bytes_out, res_bytes, "Check bytes out");
            res_word := (others => '0');
            res_word(size - 1 downto 0) := word_in(size - 1 downto 0);
            check_equal(word_out, res_word, "Check word out (unsigned)");
            sign_extend <= '1';
            wait for 2 us;
            -- Validate word_out (signed)
            check_equal(bytes_out, res_bytes, "Check bytes out");
            if size - 1 < res_word'high then
                res_word(res_word'high downto size) := (others => word_in(size - 1));
            end if;
            check_equal(word_out, res_word, "Check word out (signed)");
        end loop;
        test_runner_cleanup(runner);
    end process;
end;
