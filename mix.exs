defmodule Contentful.Mixfile do
  use Mix.Project

  alias Contentful.{
    Asset,
    ContentType,
    Collection,
    CollectionStream,
    Delivery,
    Entry,
    Locale,
    SysData,
    Space
  }

  alias Contentful.Delivery.{Assets, ContentTypes, Entries, Locales, Spaces}

  @version "0.4.1"

  def project do
    [
      app: :contentful,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Docs
      name: "Contentful SDK",
      source_url: "https://github.com/contentful-labs/contentful.ex",
      docs: [
        main: "Contentful",
        nest_modules_by_prefix: [
          Contentful,
          Contentful.Delivery
        ],
        groups_for_modules: [
          APIs: [Delivery],
          "Query DSL": [
            Contentful.Query,
            Contentful.Stream
          ],
          Contexts: [
            Assets,
            ContentTypes,
            Entries,
            Locales,
            Spaces
          ],
          "Common Structures": [
            Asset,
            Asset.Fields,
            Collection,
            CollectionStream,
            ContentType,
            ContentType.Field,
            Entry,
            Locale,
            SysData,
            Space
          ],
          Behaviours: [
            Contentful.Queryable
          ]
        ],
        logo: "assets/cf_logo.png"
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:jason, "~> 1.1"},

      # dev / test
      {:exvcr, "~> 0.12", only: :test},
      {:dogma, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},

      # docs
      {:inch_ex, "2.0.0", only: :docs}
    ]
  end

  defp description do
    """
    Contentful Elixir SDK
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :contentful,
      files: [
        "lib/",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      maintainers: [
        "David Litvak Bruno <Contentful GmbH>",
        "Florian Kraft <Contentful GmbH>"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/contentful-labs/contentful.ex",
        "Contentful" => "https://contentful.com",
        "Other Contentful SDKs" => "https://www.contentful.com/developers/docs/platforms/"
      }
    ]
  end
end
