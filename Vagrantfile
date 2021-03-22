def get_ip(index = 1)
  $ip_range.sub('xx', (index).to_s)
end

$server_nodes = 3
$client_nodes = 2
$max_nodes = $server_nodes+$client_nodes
$ip_range = '10.1.10.2xx'
$servers = Array.new($server_nodes).fill { |i| "#{get_ip(i + 1)}" }
$all_nodes = Array.new($max_nodes).fill { |i| "#{get_ip(i + 1)}" }

$ansible_groups = {
  "consul_nomad_server" => ["consul-nomad-server[1:#{$server_nodes}]"],
  "consul_nomad_client" => ["consul-nomad-client[1:#{$client_nodes}]"],
  "consul_nomad" => ["consul_nomad_server", "consul_nomad_client"],
  "all:vars" => {
    "vagrant_consul_nomad_server_ips" => $servers,
    "vagrant_consul_nomad_ips" => $all_nodes,
    "vagrant_loadbalancer_ip" => "#{get_ip(0)}"
  }
}

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/focal64"

  (1..$server_nodes).each do |i|
    config.vm.define "consul-nomad-server#{i}" do |node|
      node_ip_address = "#{get_ip(i)}"
      node.vm.network "private_network", ip: node_ip_address
      node.vm.hostname = "consul-nomad-server#{i}"
      node.ssh.insert_key = false
      node.vm.provision "file", source: "./id_rsa.pub", destination: "~/.ssh/authorized_keys"
    end
  end

  (1..$client_nodes).each do |i|
    config.vm.define "consul-nomad-client#{i}" do |node|
      node_ip_address = "#{get_ip($server_nodes+i)}"
      node.vm.network "private_network", ip: node_ip_address
      node.vm.hostname = "consul-nomad-client#{i}"
      node.ssh.insert_key = false
      node.vm.provision "file", source: "./id_rsa.pub", destination: "~/.ssh/authorized_keys"
    end
  end

  config.vm.define "loadbalancer" do |lb|
    node_ip_address = "#{get_ip(0)}"
    lb.vm.network "private_network", ip: node_ip_address
    lb.vm.hostname = "loadbalancer"
  end

  # First, we need our Consul cluster up and running
  config.vm.provision "consul", type: "ansible", run: "never" do |ansible|
    ansible.playbook = "playbook-consul.yml"
    ansible.groups = $ansible_groups
  end

  config.vm.provision "all", type: "ansible", run: "never" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.groups = $ansible_groups
  end

  # Increase memory for Virtualbox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
end
