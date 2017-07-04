defmodule SimpleRNG do
  use GenServer
  use Bitwise, only_operators: true
  @moduledoc """
  SimpleRNG is a simple random number generator using Marsaglia's MWC (multiply with carry) algorithm.
  """
  @default_seed {521288629, 362436069}

  def start_link() do
    GenServer.start_link(__MODULE__, @default_seed, name: __MODULE__)
  end

  @doc """
  Set a new seed for the RNG
  """
  def set_seed(u), do: set_seed(u >>> 16, u &&& 0xffffffff)

  def set_seed(m_w, m_z) do
    GenServer.cast __MODULE__, {:set_seed, m_w, m_z}
  end

  @doc """
  Returns random unsigned 64bit int
  """
  def get_uint do
    GenServer.call __MODULE__, :get_uint
  end

  @doc """
  Returns integer between min (inclusive) and max (exclusive)
  """
  def get_int(min, max) when max <= min, do: min
  def get_int(min, max) do
    min + rem(get_uint(), max - min)
  end

  @doc """
  Returns uniform random sample 0.0 > x < 1.0
  """
  @magic 1.0 / (:math.pow(2, 32) + 2)
  def get_uniform() do
    (get_uint() + 1.0) * @magic
  end

  @doc """
  Returns normal (Gaussian) random sample with mean 0 and standard deviation 1
  """
  def get_normal do
    # Box-Muller algorithm
    u1 = get_uniform()
    u2 = get_uniform()
    r = :math.sqrt(-2.0 * :math.log(u1))
    theta = 2.0 * :math.pi * u2
    r * :math.sin(theta)
  end

  # Swaps elements a and b in a list
  defp swap(xs, a, b) when a === b, do: xs
  defp swap(xs, a, b) when b < a, do: swap(xs, b, a)
  defp swap(xs, a, b) do
    s1 = Enum.slice(xs, 0, a)
    [x | s2] = Enum.slice(xs, a, b - a)
    [y | s3] = Enum.slice(xs, b, Enum.count(xs))
    s1 ++ [y | s2] ++ [x | s3]
  end

  # Swap element at a with element at random position before a
  defp shuffle(xs, a) when a === 0, do: xs
  defp shuffle(xs, a) do
    b = get_int(0, a)
    xs |> swap(a - 1, b) |> shuffle(a - 1)
  end

  # Fisher-Yates (Knuth) shuffle a list
  def shuffle(xs) do
    xs |> shuffle(Enum.count(xs))
  end

  ######
  # GenServer implementation

  # Marsaglia's MWC algorithm
  def handle_call(:get_uint, _from, {m_w, m_z}) do
    m_z_new = (36969 * (m_z &&& 0xffff) + (m_z >>> 16)) &&& 0xffffffff
    m_w_new = (18000 * (m_w &&& 0xffff) + (m_w >>> 16)) &&& 0xffffffff
    n = ((m_z_new <<< 16) + m_w_new) &&& 0xffffffff
    {:reply, n, {m_w_new, m_z_new}}
  end

  def handle_cast({:set_seed, m_w, m_z}, _) do
    {:noreply, {m_w &&& 0xffffffff, m_z &&& 0xffffffff}}
  end

end
