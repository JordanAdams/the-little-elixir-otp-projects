use Mix.Config

config :blitzy, :master_node, :a@localhost

config :blitzy, :slave_nodes, [:b@localhost,
                               :c@localhost,
                               :d@localhost]
