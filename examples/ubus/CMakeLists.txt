find_package(Threads REQUIRED)

add_executable(ubus
    sc_main.cpp
    ubus_example_scoreboard.cpp
    vip/ubus_bus_monitor.cpp
    vip/ubus_env.cpp
    vip/ubus_master_agent.cpp
    vip/ubus_master_monitor.cpp
    vip/ubus_master_driver.cpp
    vip/ubus_slave_agent.cpp
    vip/ubus_slave_monitor.cpp
    vip/ubus_slave_driver.cpp
    vip/ubus_transfer.cpp
)

target_link_libraries(ubus crave2uvm crave UVM::uvm-systemc SystemC::systemc Threads::Threads ${Boost_LIBRARIES})
