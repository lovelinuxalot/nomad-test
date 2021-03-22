job "http-server" {
  datacenters = ["dc1"]

  group "web" {
    count = 1
    network {
      port "http" {to = 80}
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "httpd:latest"
        volumes = [ "local/index.html:/usr/local/apache2/htdocs/index.html" ]
        ports = ["http"]

      }

      service {
        name = "hello"
        tags = ["http"]
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      template {
        data = <<EOF
        <html><head><h1>{{ key "httpd/index" }}</h1></head></html>
        EOF
        destination = "local/index.html"
        change_mode = "restart"
      }
    }
  }
}
